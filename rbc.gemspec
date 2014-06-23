$LOAD_PATH << File.expand_path('../lib', __FILE__)
require 'rbc/version'
require 'curb'
require 'nokogiri'

HOSTS = {
  :dev => 'http://www506.imsweb.com/wsapi-dev/bsi/webservices/service/'
}

root = 'package-frame.html'

host = HOSTS[:dev]
page = `http #{HOSTS[:dev]+root}`
doc = Nokogiri::HTML.parse(page)

services = {}
doc.xpath('//a')[1..-1].each do |link|
  service = link.content.gsub(/(^(?<s>[a-zA-Z]+)Service)/, '\k<s>').downcase.to_sym
  services[service] = {
    :doc_link => host + link.attributes['href'].value,
    :methods => []
  }
end

services.values.each do |service|
  page = `http #{service[:doc_link]}`
  doc = Nokogiri::HTML.parse(page)
  methods = doc.xpath('//code/b/a').map{|node| node.content}
  service[:methods] = methods.grep(/^[a-z]+/)
end

File.open('./lib/service_spec.yaml', 'wb') do |f|
  f.write(services.to_yaml)
end

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
