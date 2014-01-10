require 'nokogiri'
require 'httparty'
require 'rbc/bsi'

class RBC
  include BSIServices

  attr_accessor :sessionID, :bsi_url, :creds, :test, :common

  services = YAML::load(File.open(File.join(File.dirname(__FILE__), 'service_spec.yaml')))
  (services.keys-[:test, :common]).each do |s|
    klass = Class.new(BSIModule)
    attr_accessor s
    RBC.const_set(s.to_s.capitalize, klass)
  end


  # Initialize connection based on provided credentials
  def initialize(creds, options={:debug=>false, :stealth=>false})

    raise 'No credentials provided' if creds.class != Hash
    raise 'No url provided' if creds[:url].nil?
    raise "Invalid url" unless creds[:url].match(/^https?:\/\/(.+)\.com:\d{4}\/bsi\/xmlrpc$/)

    services = YAML::load(File.open(File.join(File.dirname(__FILE__), 'service_spec.yaml')))
    (services.keys).each do |k|
      instance_eval(
        "self.#{k} = #{k.to_s.capitalize}.new(creds, options.merge( { :methods => services[k][:methods] } ) )"
      )
    end

    @test       = Test.new(creds, options)
    @common     = Common.new(creds, options)
=begin
    # Initialize BSI service connection adaptors
    @attachment = Attachment.new(creds, options.merge({:methods => %w(download) } ) )
    @batch      = Batch.new(creds, options.merge( { :methods => %w(addVials commit create delete get getBatchProperties getHeaders getVialProperties performL1Checks performL2Checks removeVials update updateVials reserveAvailableBsiIds)}) )
    @database   = Database.new(creds, options.merge( { :methods => %w(getFields getTables normalizeValues)}) )
    @shipment   = Shipment.new(creds, options.merge( { :methods => %w(getProperties getShipment submit update uploadManifest updateDiscrepancyResolutionSuggestions)}) )
    @requisition= Requisition.new(creds, options.merge( { :methods => %w(addVials getAttachments getProperties getReqDiscrepancies removeVials save submit submitSavedRequisitions update updateDiscrepancyResolutions updatePriorities uploadAttachment uploadManifest)}) )
    @reults     = Report.new(creds, options.merge( { :methods => %w(createResultsBatch)}) )
    @report     = Report.new(creds, options.merge( { :methods => %w(count execute)}) )
    @study      = Study.new(creds, options.merge( { :methods => %w(getAttachments)}) )
    @user       = User.new(creds, options.merge( { :methods => %w(authorize create getInfo update)}) )
    @subject    = Subject.new(creds, options.merge( { :methods => %w(deleteSubject getAttachments getSubject getSubjectProperties performL1Checks performL2Checks saveNewSubject saveSubject)}) )
=end
    @common.logon

  end

end
