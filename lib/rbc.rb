require 'nokogiri'
require 'httparty'
require 'rbc/bsi'

class RBC
  include BSIServices


  attr_accessor :sessionID, :bsi_url, :creds
  attr_accessor :test, :common, :attachment, :batch, :database, :intrak, :shipment, :requisition, :report, :study, :user, :subject

  # Initialize connection based on provided credentials
  def initialize(creds, options={:debug=>false, :stealth=>false})

    raise 'No credentials provided' if creds.class != Hash
    raise 'No url provided' if creds[:url].nil?
    raise "Invalid url" unless creds[:url].match(/^https?:\/\/(.+)\.com:\d{4}\/bsi\/xmlrpc$/)

    # Initialize BSI service connection adaptors
    @test       = Test.new(creds)
    @common     = Common.new(creds)
    @attachment = Attachment.new(creds, options.merge({:methods => %w(download) } ) )
    @batch      = Batch.new(creds, options.merge( { :methods => %w(addVials commit create delete get getBatchProperties getHeaders getVialProperties performL1Checks performL2Checks removeVials update updateVials reserveAvailableBsiIds)}) )
    @database   = Database.new(creds, options.merge( { :methods => %w(getFields getTables normalizeValues)}) )
    @shipment   = Shipment.new(creds, options.merge( { :methods => %w(getProperties getShipment submit update uploadManifest updateDiscrepancyResolutionSuggestions)}) )
    @requisition= Requisition.new(creds, options.merge( { :methods => %w(addVials getAttachments getProperties getReqDiscrepancies removeVials save submit submitSavedRequisitions update updateDiscrepancyResolutions updatePriorities uploadAttachment uploadManifest)}) )
    @report     = Report.new(creds, options.merge( { :methods => %w(count execute)}) )
    @study      = Study.new(creds, options.merge( { :methods => %w(getAttachments)}) )
    @user       = User.new(creds, options.merge( { :methods => %w(authorize create getInfo update)}) )
    @subject    = Subject.new(creds, options.merge( { :methods => %w(deleteSubject getAttachments getSubject getSubjectProperties performL1Checks performL2Checks saveNewSubject saveSubject)}) )

    @common.logon

  end

end
