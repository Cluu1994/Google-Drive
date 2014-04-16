require "middleman-core"
require 'gdrive/version'

::Middleman::Extensions.register(:gdrive) do
  require 'google_drive'
  require 'gdrive/extension'
  require 'gdrive/helpers'
  # require 'gdrive/level3'
  ::Middleman::GDriveExtension
  ::Middleman::GDriveDataHelpers
  # ::Middleman::GDriveLevel3
end
