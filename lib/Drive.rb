require 'fileutils'
require 'benchmark'
require 'ruby-progressbar'
require 'multi_json'
require 'rack'
require 'oj'

class ::Hash
# add keys to hash
  def to_obj
    self.each do |k,v|

      v.to_obj if v.kind_of? Hash
      v.to_obj if v.kind_of? Array

      k=k.gsub(/\.|\s|-|\/|\'/, '_').downcase.to_sym

      ## create and initialize an instance variable for this key/value pair
      self.instance_variable_set("@#{k}", v)

      ## create the getter that returns the instance variable
      self.class.send(:define_method, k, proc{self.instance_variable_get("@#{k}")})

      ## create the setter that sets the instance variable
      self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})
    end
    return self
  end
end

class ::Array
  def to_obj
    self.map { |v| v.to_obj }
  end
end

class Drive

  # API_VERSION = 'v2'
  # CACHED_API_FILE = "drive-#{API_VERSION}.cache"
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

  def convert_to_s(object)
    if (object.is_a? Array) || (object.to_i == 0)
      return object
    else
      return object.to_i.to_s
    end
  end

  def get_sheet(banner, season, campaign, file)
    cache_file = ::File.join('data/cache', "#{file}.json")

    FileUtils.mkdir 'tmp' unless File.directory?('tmp')
    @progressbar = ProgressBar.create(:format => '%t | %a |%bᗧ%i| %p%%',
                    :progress_mark  => ' ',
                    :remainder_mark => '･',
                    :throttle_rate => 0.1)
    @progressbar.title = "== Loading #{file}"
    @progressbar.start
    time = Benchmark.realtime do
      @tmp_filepath = File.join('tmp/', file + '.xlsx')
      # require 'pry'
      # binding.pry
      @modified_date = @drive.file_by_title(
        [banner, season, campaign, file]
      ).modified_date.to_s
      if File.exist?(cache_file)
        json = Oj.object_load(::File.read(cache_file))
        @json_date = json['modified_date']
        # binding.pry
        puts "== You already have the latest revision of #{file}".green
        return json if @json_date == @modified_date
      end
      @drive.file_by_title(
        [banner, season, campaign, file]
      ).export_as_file(@tmp_filepath)
      @progressbar.increment
    end

    @progressbar.increment

    time = Benchmark.realtime do
      require 'roo'
      data = {}
      data.store('modified_date', @modified_date)
      xls = Roo::Spreadsheet.open(@tmp_filepath)
      # puts "== Parsing #{file} Spreadsheet ..."
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
          # otherwise parse the sheet into a hash
          sheet.header_line = 2 # this is stupid. theres a bug in Roo.
          # puts sheet
          data[title] = sheet.parse(headers: true)
          @progressbar.increment
        end
      end

      data
      # @worksheets = data
      # data.each do |k, v|
      # puts '== Converting to JSON'
      FileUtils.mkdir 'data/cache' unless File.directory?('data/cache')
      ::File.open(cache_file, 'w') do |f|
          # f << MultiJson.dump(
          #   {'modified_date' => @modified_date},
          #   :pretty => true, :symbolize_keys => true
          # )
          f << MultiJson.dump(
                data, :pretty => true, :symbolize_keys => true
              ).gsub('null', '""')

      end

    end
    @progressbar.finish
    # puts "Time elapsed for parsing and converting: #{time} seconds"
  end


end
