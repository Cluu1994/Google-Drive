require 'fileutils'
require 'multi_json'
require 'oj'

class Drive

  unless File.directory?('data/cache')
    FileUtils.mkdir 'data/cache'
  end

  # Create Google Authentication Session with Access Token
  settings = YAML.load(File.open('data/credentials.yml'))
  client = OAuth2::Client.new(
    settings['google']['client_id'], settings['google']['client_secret'],
    site: 'https://accounts.google.com',
    token_url: '/o/oauth2/token',
    authorize_url: '/o/oauth2/auth'
  )
  auth_token = OAuth2::AccessToken.from_hash(client, { refresh_token: settings['google']['refresh_token'] })
  auth_token = auth_token.refresh!
  $gdauth = GoogleDrive.login_with_oauth(auth_token)

  def is_float?(object)
    true if Float(object) rescue false
  end

  def get_sheet(banner, season, campaign, file)
    unless File.directory?('tmp')
      FileUtils.mkdir 'tmp'
    end
    puts "== Generating data for #{file}"
    tmp_filepath = File.join('tmp/', file + '.xlsx')
    $gdauth.file_by_title([banner, season, campaign, file]).export_as_file(tmp_filepath, 'xlsx')
    require 'roo'
    # require 'pry'

    data = {}
    xls = Roo::Spreadsheet.open(tmp_filepath)
    xls.each_with_pagename do |title, sheet|
      # if the sheet is called microcopy, copy or ends with copy, we assume
      # the first column contains keys and the second contains values.
      # Like tarbell.
      if %w(microcopy copy).include?(title.downcase) ||
        title.downcase =~ /[ -_]copy$/
        data[title] = {}
        sheet.each do |row|
          # if the key name is reused, create an array with all the entries
          if data[title].keys.include? row[0]
            if data[title][row[0]].is_a? Array
              if is_float?(row[1])
                # puts "#{row[1]} is float"
                data[title][row[0]] << row[1].to_i.to_s
              elsif row[1].nil? || row[1].empty? || row[1].blank?
                row[1] = ''
                data[title][row[0]] << row[1]
              else
                data[title][row[0]] << row[1].to_s
              end
            else
              if is_float?(row[1])
                require 'pry'
                binding.pry
                data[title][row[0]] = [data[title][row[0]], sprintf("%g", row[1].to_i.to_s)]
              elsif row[1].nil? || row[1].empty? || row[1].blank?
                row[1] = ''
                data[title][row[0]] = [data[title][row[0]], sprintf("%g", row[1].to_s)]
              else
                data[title][row[0]] = [data[title][row[0]], row[1].to_s]
              end
            end
          else
            if is_float?(row[1])
              data[title][row[0]] = sprintf("%g", row[1].to_i.to_s)
            elsif row[1].nil? || row[1].empty? || row[1].blank?
              data[title][row[0]] = ''
            else
              data[title][row[0]] = row[1].to_s
            end
            # data[title][row[0]] = row[1]
          end
        end
      else
        # otherwise parse the sheet into a hash
        sheet.header_line = 2 # this is stupid. theres a bug in Roo.
        data[title] = sheet.parse(headers: true)
      end
    end
    cache_file = ::File.join('data/cache', "#{file}.json")
    data
    ::File.open(cache_file, 'w')  { |f| f << Oj.dump(data, :mode => :object).gsub('null', '""') }

  end


end
