# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) << File.expand_path('../lib', __FILE__)
require 'rbc/version'

Gem::Specification.new do |s|
  # Metadata
  s.name          = 'rbc'
  s.version       = RBCVersion::VERSION
  s.authors       = ['Elijah Christensen']
  s.email         = ['ejd.christensen@gmail.com']
  s.summary       = 'A ruby client for managing interactions with the IMS BioSpecimen Inventory system'
  s.platform      = Gem::Platform::RUBY
  s.homepage      = 'https://github.com/elijahc/rbc'
  s.license       = 'MIT'

  # Manifest
  s.files         = `git ls-files`.split(/\n/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  # Development Dependencies
  s.add_development_dependency "bundler", "~> 1.6"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-nc"
  s.add_development_dependency "guard"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "terminal-notifier-guard"
  s.add_development_dependency "pry"
  s.add_development_dependency "pry-remote"
  s.add_development_dependency "pry-nav"
  s.add_development_dependency "coveralls"

  # Runtime Dependencies
  s.add_runtime_dependency('nokogiri', ['>= 1.5.5'])
  s.add_runtime_dependency('httparty', '~> 0.9', '>= 0.9.0')
end
