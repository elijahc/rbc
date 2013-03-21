require 'nokogiri'
require 'hashr'
require 'httparty'

class RBC
  @sessionID = nil
  @creds
  @bsi_url

  attr_accessor :sessionID, :bsi_url, :creds

  # Initialize connection based on provided credentials, default URL is production endpoint
  def initialize(creds)
    @creds = creds
    @bsi_url = @creds[:url]
    raise "Invalid url" unless @bsi_url.match(/^https:\/\/(.+)\.com:\d{4}\/bsi\/xmlrpc$/)
    self.logon
  end

  # Basic auth methods
  def logon
    @sessionID = build_call('common_logon', @creds[:user], @creds[:pass], @creds[:server])
  end

  def session(&block)
    self.logon
    yield
    self.logoff
  end

  def logoff
    # puts "Logging off..."
    build_call('common_logoff', @sessionID)
  end

  # Build xml for submission
  def build_call(method_name,*arguments)

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.methodCall{
        xml.methodName_ method_name.gsub(/_/, '.')
        xml.params{
          arguments.each do |a|
            xml.param{
              type = a.class.to_s.downcase
              send("#{type}_to_xml", xml, a)
            }
          end
        }
      }
    end

    # Submit xml to them
    send_xml( builder.to_xml )
  end

  def parse(xml)
    # Handle Errors appropriately
    unless xml['methodResponse'].keys.include?('fault')
      type = xml['methodResponse']['params']['param']['value'].keys.pop
      # Handle happy path, no errors
      send("convert_#{type}".to_sym, xml['methodResponse']['params']['param']['value'][type])
    else
      # Error occurred, extract it, notify
      code = xml['methodResponse']['fault']['value']['struct']['member'][0]['value']['int']
      message = xml['methodResponse']['fault']['value']['struct']['member'][1]['value']['string']
      raise "Error #{code}: #{message}"
    end
  end

  def send_xml(xml)

    options = {:body => xml, :ssl_version=>:SSLv3}
    response =  HTTParty.post(@bsi_url, options)

    parse(response)

  end

  def test_send_xml(xml)
    puts xml
  end

  # Methods to convert ruby structures into XML in the format BSI expects
  def float_to_xml(noko, float)
    noko.value{
      noko.float_ float
    }
  end

  def array_to_xml(noko, array)
      noko.value{
        noko.array{
          noko.data{
            array.each do |e|
              send("#{e.class.to_s.downcase}_to_xml".to_sym, noko, e)
            end
          }
        }
      }
  end

  def hash_to_xml(noko, hash)
      noko.value{
        noko.struct{
          hash.each do |k,v|
            noko.member{
              noko.name_ k.to_s
              send("#{v.class.to_s.downcase}_to_xml".to_sym, noko, v)
            }
          end
        }
      }
  end

  def string_to_xml(noko, string)
    noko.value{
      noko.string_ string
    }
  end

  def fixnum_to_xml(noko, int)
    noko.value{
      noko.int_ int
    }
  end

  def convert_struct(xml)
    hash = Hash.new
    xml['member'].each do |e|
      member_name  = e['name']
      member_value_type = e['value'].keys.first
      member_value = send("convert_#{ member_value_type }".to_sym, e['value'][member_value_type] )
      hash.store( member_name, member_value )
    end
    hash
  end

  def convert_array(xml)
    array = Array.new
    case xml['data']['value'].class.to_s.downcase
    when 'array'
      xml['data']['value'].each do |e|
        member_type  = e.keys.first
        member_value = e[member_type]
        array << send( "convert_#{member_type}".to_sym, member_value )
      end

    when 'hash'
      member_type  = xml['data']['value'].keys.first
      member_value = xml['data']['value'][member_type]
      array << send( "convert_#{member_type}".to_sym, member_value )
    end
    array
  end

  # Methods to convert XML BSI sends back to us into ruby
  def convert_int(xml)
    xml.to_i
  end

  def convert_nil(xml)
    nil
  end

  def convert_string(xml)
    xml
  end

  # TODO: Add a check to make sure its actually formatted correctly
  def method_missing(method_id, *arguments, &block)
    if method_id.to_s =~ /^(test|common|attachment|batch|database|intrak|shipment|report|study|user|subject)_[a-zA-Z]+$/
      # matches the format, assume its formatted correctly
      if method_id.to_s =~ /^(attachement|batch|database|intrak|shipment|report|study|user|subject)/ && !@sessionID.nil?
        arguments.unshift(@sessionID)
      end
      build_call(method_id.to_s, *arguments)
    else
      super
    end
  end

end
