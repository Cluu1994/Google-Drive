# Require core library
require 'middleman-core'

# Extension namespace
class Gdrive < ::Middleman::Extension

  def initialize(app, options_hash={}, &block)
    # Call super to build options from the options_hash
    super
    require 'Gauth'
    require 'google_drive'
    require 'gdrive/collection'
  end

  def after_configuration
    puts "== Google Drive Loaded"
  end

  helpers do
    def gdrive(locale, page)
      cache_file = ::File.join("data/cache", "#{locale}_#{page}.yml")
      time = Time.now
      if !::File.exist?(cache_file) || ::File.mtime(cache_file) < (time - 180)
        result = session.collection_by_title(banner).subcollection_by_title(season).subcollection_by_title(campaign).file_by_title(locale).worksheet_by_title(page).list.to_hash_array.to_yaml
        ::File.open(cache_file,"w"){ |f| f << result }
      end
      page_data_request = ::File.read(cache_file)
      return page_data_request
    end
  end

  # A Sitemap Manipulator
  # def manipulate_resource_list(resources)
  # end

  # module do
  #   def a_helper
  #   end
  # end

end

# Register extensions which can be activated
# Make sure we have the version of Middleman we expect
# Name param may be omited, it will default to underscored
# version of class name

Gdrive.register(:gdrive)
