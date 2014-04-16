require 'fileutils'
require 'rack'

module Middleman
  class GDriveExtension < Extension
    # option :offline, 'false', 'Load the data locally if set to true'

    def initialize(app, options_hash={}, &block)
      # Call super to build options from the options_hash
      super
      unless File.directory?('data/cache')
        FileUtils.mkdir 'data/cache'
      end

    #   app.extend GDriveConnector
    # end

      app.helpers do
        puts '== Google Drive Loaded'
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
          if req.params['nocache'] || req.GET.include?('nocache') && defined? req.params || defined? req.GET
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
      end
    end
  end
end
