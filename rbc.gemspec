$LOAD_PATH << File.expand_path('../lib', __FILE__)
require 'rbc/version'

Gem::Specification.new do |s|
  # Metadata
  s.name          = 'rbc'
  s.version       = RBC::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ['Elijah Christensen']
  s.email         = ['ejd.christensen@gmail.com']
  s.homepage      = 'https://github.com/elijahc/rbc'
  s.summary       = 'A ruby client for managing interactions with the IMS BioSpecimen Inventory system'

  # Manifest
  s.files         = `git ls-files`.split(/\n/)
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split(/\n/)
  s.require_paths = ['lib']

  # Dependencies
  s.add_runtime_dependency('nokogiri', ['>= 1.5.5'])
  s.add_runtime_dependency('httparty', '>= 0.9.0')

end

