module Marshaling
  # Build xml for submission
  def build_call(method_name,*arguments)

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
                raise "Nil is not an acceptable argument for method: #{method_name}"
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
      generate_exception(code, message)
    end
  end

  def send_xml(xml)

    options = {:body => xml, :ssl_version=>:SSLv3}
    if @debug
      puts "Sending:"
      puts xml
      puts ""
    end

    try_num = 0
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
    rescue BSI::IOError => e
      retry if e.action == 'retry'
    end

    if @debug
      puts "Recieved:"
      puts response.to_s
    end

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
        array << send( "convert_#{member_type}".to_sym, member_value )
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

  def convert_nil(xml)
    nil
  end

  def convert_string(xml)
    xml
  end
end
