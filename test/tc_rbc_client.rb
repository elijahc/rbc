require './bsi_client.rb'
require 'test/unit'
require 'awesome_print'

class TestBsiClient < Test::Unit::TestCase

  BETA_URL   = 'https://guava.imsweb.com:9272/bsi/xmlrpc'
  MIRROR_URL = 'https://turnip.imsweb.com:2271/bsi/xmlrpc'
  PROD_URL   = 'https://websvc.bsisystems.com:2262/bsi/xmlrpc'

  def setup

    @creds = {:user => 'christensene', :pass => 'apples123', :server => 'PCF'}
    @bsi_client = BsiClient.new(@creds, BETA_URL )

  end

  def test_logon
    @bsi_client.logon
    assert_not_equal( nil, @bsi_client.sessionID )
  end
  def test_add
    assert_equal( 4, @bsi_client.test_add(1,3) )
  end

  def test_echo
    assert_equal( 'You said: Hi there BSI', @bsi_client.test_echo('Hi there BSI') )
  end

  def test_logon
    sessionID = @bsi_client.logon
    assert_match( /^#{@creds[:server]}\+.{27}/, sessionID )
    assert_match( sessionID, @bsi_client.sessionID)
    @bsi_client.logoff
  end

  def test_report_count
    report_spec = [ {:field => 'vial.bsi_id', :operator => 'not equals', :value => '@@Missing'}
                  ]
    display = ['requisition.requisition_id', '+req_repository.req_status']
    @bsi_client.session do
      count = @bsi_client.report_count(report_spec, display)
    end
  end

  def test_report_execute

    report_spec = [{:field => 'vial.bsi_id', :operator => 'not equals', :value => '@@Missing'}]
    display = ['vial.bsi_id']
    @bsi_client.session do
      report = @bsi_client.report_execute(report_spec, display, ['vial.bsi_id'], 0, 1)
    end

  end

  def test_batch_create
    batch_props = Hash.new
    batch_props.store('batch.acess_level', "1")
    batch_props.store('batch.description', 'Add Batch example')
    batch_props.store('batch.template_path', '/system/templates/default')
    batch_props.store('batch_req_verification', '0')

    
  end

end
