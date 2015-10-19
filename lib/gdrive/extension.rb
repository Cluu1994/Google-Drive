require 'fileutils'
require 'multi_json'
require 'oj'
require 'drive'
# require 'rack/util'
# require 'pry'
module Middleman
  module Gdrive
    @config
    class Extension < ::Middleman::Extension
      option :load_sheets, nil, 'Hash of google spreadsheets to load. Hash value is the id or slug of the entry to load, hash key is the data attribute to load the sheet data into.'

      def run_once(options_hash = {}, &block)

        drive = ::Drive.new
        logger.info '== Google Drive Loaded'

        if options.load_sheets.nil?
          options.load_sheets = {en_CA: 'ca_en', fr_CA: 'ca_fr'}
        end

        options.load_sheets.each do |k, v|
          app.data.store(k, drive.get_sheet(app.config.banner, app.config.season, app.config.campaign, v)) unless app.config.offline
        end

      end

      helpers do



        def refresh(locale)
          drive = ::Drive.new
          cache_file = ::File.join('data/cache', "#{locale}.json")
          drive.get_sheet(config.banner, config.season, config.campaign, locale)
          refreshed_json = Oj.object_load(::File.read(cache_file))
          return refreshed_json
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
          auth = ::Drive.new.do_auth
          paths = split_path path
          spreadsheet = filename.lstrip.rstrip
          worksheet = worksheet.lstrip.rstrip
          begin
            req = rack[:request].query_string
          rescue
            req = nil
          end
          begin
            @banner_root = auth.collection_by_title(banner)
          rescue
            binding.pry
          end

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
            # logger.warn("Using #{@destination_path} as root for the spreadsheet.")
            result = @destination_path.file_by_title(spreadsheet).worksheet_by_title(worksheet).list.to_hash_array.to_json
          end
          ::File.open(cache_file, 'w')  { |f| f << result }
          return page_data_request = Oj.load(::File.read(cache_file))
        end

        def gdrive(locale, page, options={})
          puts locale
          if options[:refresh => true]
            json = refresh(locale)
            return page_data_request = json[page]
          end
          begin
            req = rack[:request].query_string
          rescue
            req = nil
          end
          cache_file = ::File.join('data/cache', "#{locale}.json")
          time = Time.now

          if !req.nil? && req.params['refresh'] || !req.nil? && req.GET.include?('refresh')
            json = refresh(locale)
            return page_data_request = json[page]
          end

          if !::File.exist?(cache_file) || ::File.mtime(cache_file) < (time - app.config.cache_duration) || ENV['STAGING'] == 'heroku'
            json = refresh(locale)
            return page_data_request = json[page]
          else
            unless build?
              puts "== You are currently viewing #{page} using the offline mode" if offline
            end

            json = Oj.object_load(::File.read(cache_file))
            return page_data_request = json[page]
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

      def ready
        run_once
      end
    end
  end
end
