require 'nokogiri'
require 'hashr'
require 'httparty'
require 'rbc/bsi'
require 'rbc/marshaler'

class RBC
  include BSI
  include BSIServices
  include Marshaling

  SSL_RETRY_LIMIT = 5
  @sessionID = nil
  @creds
  @bsi_url
  @debug

  attr_accessor :sessionID, :bsi_url, :creds, :debug
  attr_accessor :test, :common, :attachment, :batch, :database, :intrak, :shipment, :requisition, :report, :study, :user, :subject

  # Initialize connection based on provided credentials
  def initialize(creds)
    raise 'No credentials provided' if creds.class != Hash
    @creds = creds
    raise 'No url provided' if @creds[:url].nil?
    @bsi_url = @creds[:url]
    raise "Invalid url" unless @bsi_url.match(/^https:\/\/(.+)\.com:\d{4}\/bsi\/xmlrpc$/)
    self.logon

    # Initialize BSI service connection adaptors
    @test       = Test.new
    @common     = Common.new
    @attachment = Attachment.new
    @batch      = Batch.new
    @databse    = Database.new
    @shipment   = Shipment.new
    @requisition= Requisition.new
    @report     = Report.new
    @study      = Study.new
    @user       = User.new
    @subject    = Subject.new

  end

  # Exception dispatcher based on error logged by BSI
  def generate_exception(code, message)
    case code
    when 9000
      # 9000 level
      case message
      when 'Logon failed: Broken pipe'
        raise BSI::IOError.new(code, message, 'retry')
      end
    else
      raise BSI::Error.new(code, message)
    end
  end

end
