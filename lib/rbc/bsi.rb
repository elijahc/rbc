module Marshaling
  ####################################
  #           Exceptions             #
  ####################################

  # General exception
  class Error < StandardError

    attr_reader :message, :code
    attr_accessor :action
    def initialize(code=nil, message=nil, action=nil)
      @message  = message
      @code     = code
      @action   = action
    end

    def to_s
      "#{@code}: #{@message}"
    end

  end

  class IOError < Error; end

  class IncorrectMethodSignature < Error; end

  # Exception dispatcher based on error logged by BSI

  class Marshaler

    SSL_RETRY_LIMIT = 5

    def generate_exception(code, message)
      case code
      when 9000
        # 9000 level
        case message
        when 'Logon failed: Broken pipe'
          raise IOError.new(code, message, 'retry')
        end
      else
        raise Error.new(code, message)
      end
    end

    def initialize(url, options)
      @bsi_url = url
      @debug   = options[:debug]
      @stealth = options[:stealth]
    end

    # Build xml for submission
    def build_call(method_name, *arguments)

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.methodCall{
          xml.methodName_ method_name.gsub(/_/, '.')
          xml.params{
            arguments.each do |a|
              xml.param{
                unless a.nil?
                  type = a.class.to_s.downcase
                  send("#{type}_to_xml", xml, a)
                else
                  raise "Nil is not an acceptable argument for method: #{method_name}#{arguments.to_s.gsub(/\]/, ')').gsub(/\[/, '(')}"
                end
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
        code = xml['methodResponse']['fault']['value']['struct']['member'][0]['value']['int'].to_i
        message = xml['methodResponse']['fault']['value']['struct']['member'][1]['value']['string']
        # Temp hack to workaround
        #raise "#{code}: #{message}"
        # How we should generate exceptions
        generate_exception(code, message)
      end
    end

    def send_xml( xml)

      options = {:body => xml}
      if @bsi_url.match(/https/)
        options.merge(:ssl_version=>:SSLv3)
      end
      if @debug
        puts "Sending:"
        puts xml
        puts ""
      end

      try_num = 0
      unless @stealth
        begin
          response =  HTTParty.post(@bsi_url, options)
        rescue OpenSSL::SSL::SSLError => e
          if try_num < SSL_RETRY_LIMIT
            try_num = try_num + 1
            puts "SSL error.  Retry #{try_num}"
            retry
          else
            raise e
          end
        rescue IOError => e
          puts 'Broken Pipe error, retrying'
          retry if e.action == 'retry'
        end
      end

      unless @stealth
        if @debug
          puts "Recieved:"
          puts Nokogiri::XML(response.body, &:noblanks)
        end

        parse(response)
      end

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
                send("#{v.class.to_s.downcase}_to_xml".to_sym, noko, v) unless v.nil?
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
        member_value = send("convert_#{ member_value_type.gsub(/\./, '_') }".to_sym, e['value'][member_value_type] )
        hash.store( member_name, member_value )
      end
      hash
    end

    def convert_array(xml)
      array = Array.new
      unless xml['data'].nil?
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
          array << send( "convert_#{member_type.gsub(/\./, '_')}".to_sym, member_value )
        end
      else
        array = nil
      end
      array
    end

    # Methods to convert XML BSI sends back to us into ruby
    def convert_int(xml)
      xml.to_i
    end

    def convert_boolean(xml)
      xml
    end

    def convert_nil(xml)
      nil
    end

    def convert_string(xml)
      xml
    end

    def convert_dateTime_iso8601(xml)
      DateTime.parse(xml)
    end
  end
end

module BSIServices
  class BSIModule
    include Marshaling
    @@bsi_url     = nil
    @@session_id  = nil
    @@debug       = false

    def initialize(creds, options={})
      methods = []
      methods = options[:methods] if options[:methods]
      @@debug = options[:debug]
      @@stealth = options[:stealth]
      @@bsi_url = creds[:url]
      @@marshal = Marshaler.new(@@bsi_url, options)
      add_methods(methods)
    end

    def add_methods(methods)
      methods.each do |meth|
        define_singleton_method meth, ->(*arguments) { @@marshal.build_call( "#{self.class.to_s.split('::').last.downcase}.#{__method__}", *arguments.unshift( @@session_id ) ) }
      end
    end

  end

  class Test < BSIModule

    def add(*arguments)
      build_call('test.add', *arguments)
    end

    def echo(string)
      build_call('test.echo', string)
    end

  end

  class Common < BSIModule
    # Special class where we don't want to pass SESSION_ID to all of its methods

    def initialize(creds)
      @creds = creds
      super
    end

    def logon
      session_id = @@marshal.build_call( 'common.logon', @creds[:user], @creds[:pass], @creds[:server] )
      if @@stealth
        @@session_id = 'DUMMY-SESSION-ID'
      else
        @@session_id = session_id
      end
    end

    def logoff
      @@marshal.build_call('common.logoff', @@session_id)
    end

  end

  class Attachment < BSIModule; end
  class Batch < BSIModule; end
  class Billing < BSIModule; end
  class Database< BSIModule; end
  class Report < BSIModule; end
  class Requisition < BSIModule; end
  class Shipment < BSIModule; end
  class Study < BSIModule; end
  class Subject < BSIModule; end
  class User < BSIModule; end

end
