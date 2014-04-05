require 'middleman'
require 'gdrive/version'

::Middleman::Extensions.register(:gdrive) do
  require 'gdrive/extension'
  ::Middleman::GDriveExtension
end
