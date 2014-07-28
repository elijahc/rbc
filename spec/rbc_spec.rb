require 'spec_helper'

describe RBC do

  it 'has a version number' do
    expect(RBC::VERSION).not_to be_nil
    expect(RBC::VERSION).to be_instance_of String
  end

  describe '#new' do
    it 'expects a Hash' do
      expect{RBC.new}.to raise_error(ArgumentError)
      expect{RBC.new([])}.to raise_error(ArgumentError)
      expect{RBC.new({:user => 'me'})}.to raise_error(ArgumentError)
      expect{RBC.new({:user => 'me', :pass => 'too'})}.to raise_error(ArgumentError)
    end

    it 'takes an optional instance parameter' do
      @bsi = RBC.new({:user => 'me', :pass => 'pass', :server => 'server'}, {:instance => :mirror})
      expect(@bsi.url_target).to eq(RBC::BSI_INSTANCES[:mirror])
    end
  end


end
