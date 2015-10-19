require 'middleman-core'
require_relative 'gdrive/version'
require 'google_drive'
require_relative 'gdrive/extension'

# ::Middleman::Extensions.register(:gdrive) do
#
#
# end


::Middleman::Extensions.register(:gdrive, ::Middleman::Gdrive::Extension)
