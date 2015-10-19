# If you have OpenSSL installed, we recommend updating
# the following line to use "https"
source 'http://rubygems.org'

# Specify your gem's dependencies in gdrive.gemspec
gemspec

gem 'middleman-core', github: 'middleman/middleman', branch: 'master'
gem 'middleman-cli', github: 'middleman/middleman', branch: 'master'

group :development do
  gem 'google_drive', :git => 'https://github.com/gimite/google-drive-ruby.git', :branch => 'drive_api'
  gem 'rake'
  gem 'rdoc'
  gem 'yard'

end

group :test do
  gem 'cucumber'
  gem 'fivemat'
  gem 'aruba'
  gem 'rspec'
end
