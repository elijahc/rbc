require 'rspec/core/rake_task'
require 'bundler/gem_tasks'
require 'nokogiri'
require 'curb'
require 'yaml'

namespace :fetch do
  desc "Fetch list of service endpoints and methods and store to file"
  task "services" do
    hosts = {
      :dev  => 'http://www506.imsweb.com/wsapi-dev/bsi/webservices/service/',
      :prod => 'http://www506.imsweb.com/wsapi-prod/bsi/webservices/service/'
    }

    root = 'package-frame.html'

    host = hosts[:dev]
    page = `http #{hosts[:dev]+root}`
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

  end
end

task :default => :spec
