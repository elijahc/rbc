require 'yaml'
require 'rbc/version'
require 'rbc/bsi'

class RBC
  include RBCVersion
  include BSIServices
  BSI_INSTANCES = {
    :mirror     => 'https://websvc-mirror.bsisystems.com:2271/bsi/xmlrpc',
    :staging    => 'https://websvc-mirror.bsisystems.com:2271/bsi/xmlrpc',
    :production => 'https://websvc.bsisystems.com:2262/bsi/xmlrpc'
  }

  attr_accessor :session_id, :url_target, :creds, :test, :common

  services = YAML::load(File.open(File.join(File.dirname(__FILE__), 'service_spec.yaml')))
  (services.keys-[:test, :common]).each do |s|
    klass = Class.new(BSIModule)
    attr_accessor s
    self.const_set(s.to_s.capitalize, klass)
  end

  # Initialize connection based on provided credentials
  def initialize(creds, options={:debug=>false, :stealth=>false, :instance=>:mirror})
    raise ArgumentError, """
No credentials hash provided, expected a hash in the form of:
  {
    :user     => 'username',
    :pass     => 'password',
    :server   => 'MYBSIDATABASE',
  }
    """ if creds.class != Hash || creds[:user].nil? || creds[:pass].nil? || creds[:server].nil?
    raise ArgumentError, 'Please provide either a valid instance or specify a custom url using option key :url => \'https://...\'' if BSI_INSTANCES[options[:instance]].nil? && options[:url].nil? && options[:stealth]==false
    options[:url] = BSI_INSTANCES[options[:instance]] unless options[:url]
    self.url_target = options[:url]

    raise RuntimError, "Invalid url" unless url_target.match(/^https?:\/\/(.+):\d{4}\/bsi\/xmlrpc$/)

    self.session_id = creds[:session_id] if creds[:session_id]
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
    @common.logon if @session_id.nil?
  end
end
