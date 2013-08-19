require 'spec_helper'

describe Msgr::Railtie do

  describe 'configuration options' do
    let(:config) { Rails.configuration }

    it 'should have `msgr` key' do
      expect(config).to respond_to :msgr
    end
  end
end
