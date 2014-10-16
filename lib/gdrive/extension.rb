require 'fileutils'
require 'multi_json'
require 'oj'
require 'drive'
module Middleman
  class GDriveExtension < ::Middleman::Extension
    option :load_sheets, {}, 'Hash of google spreadsheets to load. Hash value is the id or slug of the entry to load, hash key is the data attribute to load the sheet data into.'
    #include Middleman::CoreExtensions

    def initialize(klass, options_hash = {}, &block)
      # Call super to build options from the options_hash
      super
      # require 'google_drive/session'
      drive = ::Drive.new
      app = klass.inst # where would you store the app instance?
      options.load_sheets.each do |k, v|
        app.data.store(k, drive.get_sheet(app.config.banner, app.config.season, app.config.campaign, v))
      end
      require 'fileutils'
      FileUtils.rm_rf 'tmp'
    end

    def after_configuration
      app.logger.info '== Google Drive Loaded'



      app.helpers do

        def gdrive(locale, page)

          # session = $gdauth.file_by_title([banner, season, campaign, locale])
          # locale = locale.lstrip.rstrip
          # page = page.lstrip.rstrip
          drive = ::Drive.new
          cache_file = ::File.join('data/cache', "#{locale}.json")
          time = Time.now
          if offline
            puts "== You are currently viewing #{page} using the offline mode".green
            json = Oj.object_load(::File.read(cache_file))
            return page_data_request = json[page]
          end
          # if !req.nil? && req.params['nocache'] || !req.nil? && req.GET.include?('nocache')
          #   puts "== You are viewing #{page} directly from google drive".red
          #   return page_data_request = Oj.load(session.worksheet_by_title(page).list.to_hash_array.to_json)
          if !req.nil? && req.params['refresh'] || !req.nil? && req.GET.include?('refresh')
            puts "== Refreshing cache file for #{page}".green
            # result = session.worksheet_by_title(page).list.to_hash_array.to_json
            # ::File.open(cache_file, 'w')  { |f| f << result }
            drive.get_sheet(config.banner, config.season, config.campaign, locale)
            json = Oj.object_load(::File.read(cache_file))
            return page_data_request = json[page]
            # return page_data_request = data.cache[locale][page]
            # return page_data_request = Oj.load(::File.read(cache_file))
          else
            if !::File.exist?(cache_file) || ::File.mtime(cache_file) < (time - cache_duration)
              # binding.pry
              # result = session.worksheet_by_title(page).list.to_hash_array.to_json
              # ::File.open(cache_file, 'w')  { |f| f << result }
              drive.get_sheet(config.banner, config.season, config.campaign, locale)
            end
            json = Oj.object_load(::File.read(cache_file))
            return page_data_request = json[page]
            # return page_data_request = data.cache[locale][page]
            # return page_data_request = Oj.load(::File.read(cache_file))
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
