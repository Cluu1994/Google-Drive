require 'middleman'
require 'gdrive/version'

::Middleman::Extensions.register(:gdrive) do
  require 'google_drive'
  require 'gdrive/extension'
  ::Middleman::GDriveExtension
end
