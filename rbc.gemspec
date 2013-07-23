Gem::Specification.new do |s|
  # Metadata
  s.name          = 'rbc'
  s.version       = '0.2.2'
  s.authors       = ['Elijah Christensen']
  s.email         = ['']
  s.homepage      = 'https://github.com/elijahc/rbc'
  s.date          = '2013-03-20'
  s.summary       = 'A ruby client for managing interactions with the IMS BioSpecimen Inventory system'

  # Manifest
  s.files         = `git ls-files`.split(/\n/)
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split(/\n/)
  s.require_paths = ['lib']

  # Dependencies
  s.add_runtime_dependency('nokogiri', ['>= 1.5.5'])
  s.add_runtime_dependency('hashr', '>= 0.0.22')
  s.add_runtime_dependency('httparty', '>= 0.9.0')

end

