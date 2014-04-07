require 'middleman'
require 'gdrive/version'

::Middleman::Extensions.register(:gdrive) do
  require 'google_drive'
  require 'gdrive/extension'
  require 'gdrive/helpers'
  ::Middleman::GDriveExtension
end
