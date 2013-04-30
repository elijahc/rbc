require 'nokogiri'
require 'hashr'
require 'httparty'
require 'rbc/bsi'

class RBC
  include BSIServices


  attr_accessor :sessionID, :bsi_url, :creds
  attr_accessor :test, :common, :attachment, :batch, :database, :intrak, :shipment, :requisition, :report, :study, :user, :subject

  # Initialize connection based on provided credentials
  def initialize(creds, debug=false)

    raise 'No credentials provided' if creds.class != Hash
    raise 'No url provided' if creds[:url].nil?
    raise "Invalid url" unless creds[:url].match(/^https:\/\/(.+)\.com:\d{4}\/bsi\/xmlrpc$/)

    # Initialize BSI service connection adaptors
    @test       = Test.new(creds)
    @common     = Common.new(creds)
    @attachment = Attachment.new(creds, {:debug=>debug, :methods => %w(download) } )
    @batch      = Batch.new(creds, {:debug=>debug, :methods => %w(addVials commit create delete get getBatchProperties getHeaders getVialProperties performL1Checks performL2Checks removeVials update updateVials)})
    @database   = Database.new(creds, {:debug=>debug, :methods => %w(getFields getTables normalizeValues)})
    @shipment   = Shipment.new(creds, {:debug=>debug, :methods => %w(getProperties getShipment submit update updateDiscrepancyResolutionSuggestions)})
    @requisition= Requisition.new(creds, {:debug=>debug, :methods => %w(addVials getAttachments getProperties getReqDiscrepancies removeVials save submit submitSavedRequisitions update updateDiscrepancyResolutions updatePriorities uploadAttachment uploadManifest)})
    @report     = Report.new(creds, {:debug=>debug, :methods => %w(count execute)})
    @study      = Study.new(creds, {:debug=>debug, :methods => %w(getAttachments)})
    @user       = User.new(creds, {:debug=>debug, :methods => %w(authorize create getInfo update)})
    @subject    = Subject.new(creds, {:debug=>debug, :methods => %w(deleteSubject getAttachments getSubject getSubjectProperties performL1Checks performL2Checks saveNewSubject saveSubject)})

    @common.logon

  end

end
