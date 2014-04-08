require 'fileutils'

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
    

    helpers do
      def session
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
        gdauth = GoogleDrive.login_with_oauth(auth_token)
        return session = gdauth.collection_by_title(banner).subcollection_by_title(season).subcollection_by_title(campaign)
      end

      def gdrive(locale, page)
        locale = locale.lstrip.rstrip
        page = page.lstrip.rstrip
        cache_file = ::File.join('data/cache', "#{locale}_#{page}.yml")
        time = Time.now
        if offline
          puts "== You are currently viewing #{page} using the offline mode".green
          return page_data_request = YAML.load(::File.read(cache_file))
        end
        if req.params['nocache'] || req.GET.include?('nocache')
          puts "== You are viewing #{page} directly from google drive".red
          return page_data_request = YAML.load(session.file_by_title(locale).worksheet_by_title(page).list.to_hash_array.to_yaml)
        else
          if !::File.exist?(cache_file) || ::File.mtime(cache_file) < (time - cache_duration)
            result = session.file_by_title(locale).worksheet_by_title(page).list.to_hash_array.to_yaml
            ::File.open(cache_file, 'w')  { |f| f << result }
          end
          return page_data_request = YAML.load(::File.read(cache_file))
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
    end
    end
  end
end
