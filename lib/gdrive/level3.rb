module Middleman
  class GDriveLevel3 < GDriveExtension

    def initialize(app, options_hash={}, &block)
      # Call super to build options from the options_hash
      super
      if app.generate_l3
        app.ready do

          if app.version == 'icongo'
            icongo_locales.each do |icongo_locale|
              level3(icongo_locale)
            end
          else
            Dir.foreach('locales') do |proxy_lang|
              level3(proxy_lang)
            end
          end

          
        end
      end
    end
  end
end
