# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "gdrive/version"

Gem::Specification.new do |s|
  s.name        = "gdrive"
  s.version     = Middleman::GDrive::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["ALDO Digital Lab"]
  # s.email       = ["email@example.com"]
  # s.homepage    = "http://example.com"
  s.summary     = %q{Google Drive for Aldo Group}
  # s.description = %q{A longer description of your extension}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib/google-drive-ruby/lib"]
  s.require_paths = ["lib"]

  # The version of middleman-core your extension depends on
  s.add_runtime_dependency("middleman-core", [">= 3.2.2"])

  # Additional dependencies
  s.add_runtime_dependency("oauth2", [">= 1.0.0"])
  s.add_runtime_dependency("google_drive", ["1.0.1"])
  s.add_runtime_dependency('ruby-progressbar', ">= 1.6.0")
  s.add_runtime_dependency('multi_json', [">= 1.10.1"])
  s.add_runtime_dependency("oj", [">= 2.10.3"])
  s.add_runtime_dependency("roo", ">= 1.13.2")
  s.add_runtime_dependency('retriable', '~> 1.4')
  # s.add_runtime_dependency('google-api-client', '< 0.8')
  s.add_runtime_dependency('rubyXL', '3.3')
  s.add_runtime_dependency('archieml', '~> 0.1')
  s.add_runtime_dependency('mime-types', '~> 2.4')
end
