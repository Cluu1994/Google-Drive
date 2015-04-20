require 'fileutils'
require 'oj'
require 'pry'
module Middleman
  class GDriveExtension < ::Middleman::Extension
    #include Middleman::CoreExtensions

    def initialize(app, options_hash={}, &block)
      # Call super to build options from the options_hash
      super
      # require 'google_drive/session'
      unless File.directory?('data/cache')
        FileUtils.mkdir 'data/cache'
      end
    end

    def after_configuration
      app.logger.info '== Google Drive Loaded'

      app.helpers do

        def auth
          # Create Google Authentication Session with Access Token
          settings = YAML.load(File.open('data/credentials.yml'))
          client = OAuth2::Client.new(
              settings['google']['client_id'], settings['google']['client_secret'],
              site: 'https://accounts.google.com',
              token_url: '/o/oauth2/token',
              authorize_url: '/o/oauth2/auth'
          )
          auth_token = OAuth2::AccessToken.from_hash( client, { refresh_token: settings['google']['refresh_token'] })
          auth_token = auth_token.refresh!
          return GoogleDrive.login_with_oauth(auth_token)
        end

        def split_path(path)
          array = []
          until %w(/ .).include? path
            array << File.basename(path)
            path = File.dirname(path)
          end
          array.reverse
        end

        def fetch_path(source, dest)
          source.subcollection_by_title(dest)
        end

        def getSheet(path, filename, worksheet)
          paths = split_path path
          spreadsheet = filename.lstrip.rstrip
          worksheet = worksheet.lstrip.rstrip
          @banner_root = auth.collection_by_title(banner)
          cache_file = ::File.join('data/cache', "#{spreadsheet}_#{worksheet}.json")
          # time = Time.now
          paths.each do |spreadsheet_path|
            if @dir.nil?
              @dir = fetch_path(@banner_root, spreadsheet_path)
            else
              @dir = fetch_path(@dir, spreadsheet_path)
            end
          end

          (@dir.nil?) ? destination_path = @destination_path : @destination_path = @dir

          if offline
            puts "== You are currently viewing #{page} using the offline mode" unless build?
            offline_load(page, cache_file)
          end
          if !req.nil? && req.params['nocache'] || !req.nil? && req.GET.include?('nocache')
            puts "== You are viewing #{page} directly from google drive"
            nocache_load(destination_path, spreadsheet, worksheet)
          elsif !req.nil? && req.params['refresh'] || !req.nil? && req.GET.include?('refresh')
            puts "== Refreshing cache file for #{page}"
            refresh_cache(destination_path, spreadsheet, worksheet, cache_file)
          else
            refresh_cache(destination_path, spreadsheet, worksheet, cache_file) if outdated_cache_file(cache_file)
            return page_data_request = Oj.load(::File.read(cache_file))
          end
        end

        def outdated_cache_file(file)
          time = Time.now
          !::File.exist?(file) || ::File.mtime(file) < (time - cache_duration)
        end

        def offline_load(page, cache_file)
          return page_data_request = Oj.load(::File.read(cache_file))
        end

        def nocache_load(root, spreadsheet, worksheet)
          return page_data_request =  Oj.load(root.file_by_title(spreadsheet).worksheet_by_title(worksheet).list.to_hash_array.to_json)
        end

        def refresh_cache(root, spreadsheet, worksheet, cache_file)
          begin
            result = root.file_by_title(spreadsheet).worksheet_by_title(worksheet).list.to_hash_array.to_json
          rescue
            # binding.pry
            logger.warn("Using #{@destination_path} as root for the spreadsheet.")
            result = @destination_path.file_by_title(spreadsheet).worksheet_by_title(worksheet).list.to_hash_array.to_json
          end
          ::File.open(cache_file, 'w')  { |f| f << result }
          return page_data_request = Oj.load(::File.read(cache_file))
        end

        def session
          return auth.collection_by_title(banner).subcollection_by_title(season).subcollection_by_title(campaign)
        end

        def gdrive(locale, page)
          locale = locale.lstrip.rstrip
          page = page.lstrip.rstrip
          cache_file = ::File.join('data/cache', "#{locale}_#{page}.json")
          time = Time.now
          if offline
            puts "== You are currently viewing #{page} using the offline mode" unless build?
            return page_data_request = Oj.load(::File.read(cache_file))
          end
          if !req.nil? && req.params['nocache'] || !req.nil? && req.GET.include?('nocache')
            puts "== You are viewing #{page} directly from google drive"
            return page_data_request = Oj.load(session.file_by_title(locale).worksheet_by_title(page).list.to_hash_array.to_json)
          elsif !req.nil? && req.params['refresh'] || !req.nil? && req.GET.include?('refresh')
            puts "== Refreshing cache file for #{page}"
            result = session.file_by_title(locale).worksheet_by_title(page).list.to_hash_array.to_json
            ::File.open(cache_file, 'w')  { |f| f << result }
            return page_data_request = Oj.load(::File.read(cache_file))
          else
            if !::File.exist?(cache_file) || ::File.mtime(cache_file) < (time - cache_duration)
              result = session.file_by_title(locale).worksheet_by_title(page).list.to_hash_array.to_json
              ::File.open(cache_file, 'w')  { |f| f << result }
            end
            return page_data_request = Oj.load(::File.read(cache_file))
          end
        end
        def getItemByPosition(grid_position, page_data_request)
          item_by_position = page_data_request.find { |k| k['grid_position'] == grid_position }
          item_by_position ? item_by_position : '<span>no item found!</span>'
        end

        def getItemByPositionAndType(grid_position, page_type, page_data_request)
          item_by_position = page_data_request.find {|k| k['grid_position'] == grid_position && k['type'] == page_type }
          item_by_position ? item_by_position : '<span>no item found!</span>'
        end

        def getItemByType(type, page_data_request)
          item_by_position = page_data_request.find { |k| k['type'] == type}
          item_by_position ? item_by_position : '<span>no item found!</span>'
        end

        def getItemByPage(page, page_data_request)
          item_by_position = page_data_request.find { |k| k['page'] == page}
          item_by_position ? item_by_position : '<span>no item found!</span>'
        end

        def getAllItemsByPosition(grid_position, page_data_request)
          item_by_position = page_data_request.find_all {|k| k['grid_position'] == grid_position }
          item_by_position ? item_by_position : '<span>no item found!</span>'
        end

        def getAllItemsByType(type, page_data_request)
          item_by_position = page_data_request.find_all {|k| k['type'] == type }
          item_by_position ? item_by_position : '<span>no item found!</span>'
        end

        def getAllItemsByPage(page, page_data_request)
          item_by_position = page_data_request.find_all { |k| k['page'] == page }
          item_by_position ? item_by_position : '<span>no item found!</span>'
        end

        def getCell(grid_position, column_name, page_data_request)
          getItemByPosition(grid_position, page_data_request)[column_name]
        end

        def getData(data_type, data_name, page_data)
          request = page_data.find_all {|k| k["#{data_type}"].match /#{data_name}/}
          if request.length == 1
            return request[0]
          else
            return request ? request : 'Error: No Data Found'
          end
        end

        def getAllData(data_type, data_name, page_data)
          return page_data.find_all { |k| k["#{data_type}"].match /#{data_name}(.*)/ }
        end

        def get_value_from_id(id, data)
          q = data.find_all {|k| k['id'] == id}
          return q[0]['value']
        end
      end
    end
  end
end
