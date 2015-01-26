require 'fileutils'
require 'ruby-progressbar'
require 'multi_json'
require 'rack'
require 'oj'

class Drive

  CREDENTIAL_STORE_FILE = 'data/credentials.yml'

  def initialize

    # Create Google Authentication Session with Access Token
    settings = YAML.load(File.open(CREDENTIAL_STORE_FILE))

    @drive = nil

    client = OAuth2::Client.new(
      settings['google']['client_id'], settings['google']['client_secret'],
      site: 'https://accounts.google.com',
      token_url: '/o/oauth2/token',
      authorize_url: '/o/oauth2/auth'
    )
    auth_token = OAuth2::AccessToken.from_hash(
      client,
      refresh_token: settings['google']['refresh_token']
    )
    auth_token = auth_token.refresh!
    @drive = GoogleDrive.login_with_oauth(auth_token)

    return @drive
  end

  def numeric?(value)
    Float(value) != nil rescue false
  end

  def trim(num)
    i, f = num.to_i, num.to_f
    i == f ? i : f
  end

  def stringify_array_values(object)
    object.each do |hash, value|
      hash.each do |k, v|
        if numeric?(hash[k])
            hash[k] = trim(v).to_s
        else
          hash[k] = v.to_s
        end
      end
    end
  end

  def get_sheet(banner, season, campaign, file)

      cache_file = ::File.join('data/cache', "#{file}.json")

      @progressbar = ProgressBar.create(:format => '%t | %a |%bᗧ%i| %p%%',
                      :progress_mark  => ' ',
                      :remainder_mark => '･',
                      :throttle_rate => 0.1)
      @progressbar.title = "== Loading #{file}"
      @progressbar.start

        @tmp_file = Tempfile.new(['gdoc', '.xlsx'], binmode: true)
        @tmp_filepath = @tmp_file.path

        if File.exist?(cache_file) && ENV['STAGING'].nil?
          json = Oj.object_load(::File.read(cache_file))
          @sheet_key = json['key'] || ''
          @modified_date = DateTime.parse(@drive.file_by_id(@sheet_key).modified_date.to_s).to_time
          @json_date = DateTime.parse(json['modified_date']).to_time

          if @json_date == @modified_date
            puts "== You already have the latest revision of #{file}"
            return json
          else
            uri =  @drive.file_by_id(@sheet_key).api_file['exportLinks'][
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
            get_resp = @drive.execute!(uri: uri)
            @tmp_file.write get_resp.body
            @tmp_file.close
          end
        else
          @sheet_key = @drive.file_by_title([banner, season, campaign, file]).key
          @modified_date = @drive.file_by_id(@sheet_key).modified_date.to_s
          uri =  @drive.file_by_id(@sheet_key).api_file['exportLinks'][
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
          get_resp = @drive.execute!(uri: uri)
          @tmp_file.write get_resp.body
          @tmp_file.close
        end
        @progressbar.increment

      @progressbar.increment

        require 'roo'
        data = {}
        data.store('key', @sheet_key)
        data.store('modified_date', @modified_date)
        xls = Roo::Spreadsheet.open(@tmp_filepath)
        xls.each_with_pagename do |title, sheet|
          @progressbar.increment
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
                  data[title][row[0]] << row[1]
                else
                  data[title][row[0]] = [data[title][row[0]], row[1]]
                end
              else
                data[title][row[0]] = row[1].gsub(/[^0-9]/,'')
              end
            end
          else
            sheet.header_line = 2 # this is stupid. theres a bug in Roo.
            begin
              data[title] = stringify_array_values(sheet.parse(headers: true))
            rescue NoMethodError => err
            end
            @progressbar.increment
          end
        end

        # data

        FileUtils.mkdir 'data/cache' unless File.directory?('data/cache')
        ::File.open(cache_file, 'w') do |f|
            f << MultiJson.dump(
                  data,
                  :pretty => true,
                  :symbolize_keys => true
                )
        end
      @progressbar.finish
  end
end
