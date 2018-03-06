require 'rspec/core/rake_task'
require 'bundler/gem_tasks'
require 'curb'
require 'pry'
require 'httparty'
require 'yaml'
require 'json'

namespace :fetch do
  desc "Fetch list of service endpoints and methods and store to file"
  task "services" do
    hosts = {
      :uat  => 'https://rest-uat.bsisystems.com/api/rest/swagger.json',
      :mirror  => 'https://rest-mirror.bsisystems.com/api/rest/swagger.json',
      :prod => 'https://rest.bsisystems.com/api/rest/swagger.json'
    }

    hosts.each do |k,url|
      res = HTTParty.get(url)
      path = './tmp/'
      filename = path+"#{k}_swagger.yaml"
      File.open(filename, "w") do |file|
        file.write(res.parsed_response.to_yaml)
      end
    end


    #File.open('./lib/service_spec.yaml', 'wb') do |f|
      #f.write(services.to_yaml)
    #end

  end
end

task :default => :spec
