# frozen_string_literal: true

require 'spec_helper'

describe Msgr::Railtie do
  describe 'configuration options' do
    let(:config) { Rails.configuration }

    it 'has `msgr` key' do
      expect(config).to respond_to :msgr
    end
  end

  describe '#load' do
    before do
      allow(Msgr).to receive(:start)
      allow(Msgr.client).to receive(:connect)
    end

    context 'without checkcredentials value' do
      it 'connects to rabbitmq directly to check credentials' do
        described_class.load({})
        expect(Msgr.client).to have_received(:connect)
      end
    end

    context 'with checkcredentials is false' do
      it 'connects to rabbitmq directly to check credentials' do
        described_class.load({checkcredentials: false})
        expect(Msgr.client).not_to have_received(:connect)
      end
    end
  end
end
