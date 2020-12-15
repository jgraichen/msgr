# frozen_string_literal: true

require 'spec_helper'

describe Msgr::Railtie do
  describe 'configuration options' do
    let(:config) { Rails.configuration }

    it 'has `msgr` key' do
      expect(config).to respond_to :msgr
    end
  end

  describe '#parse_config' do
    subject { parse_config }

    let(:settings) { {} }
    let(:parse_config) { described_class.parse_config settings }

    context 'with config without url' do
      let(:settings) { {'test' => {hans: 'otto'}} }

      it { expect { parse_config }.to raise_error 'Could not load rabbitmq environment config: URI missing.' }
    end

    context 'with invalid autostart value' do
      let(:settings) { {'test' => {uri: 'hans', autostart: 'unvalid'}} }

      it { expect { parse_config }.to raise_error 'Invalid value for rabbitmq config autostart: "unvalid"' }
    end

    context 'with invalid checkcredentials value' do
      let(:settings) { {'test' => {uri: 'hans', checkcredentials: 'unvalid'}} }

      it { expect { parse_config }.to raise_error 'Invalid value for rabbitmq config checkcredentials: "unvalid"' }
    end

    context 'with invalid raise_exceptions value' do
      let(:settings) { {'test' => {uri: 'franz', raise_exceptions: 'unvalid'}} }

      it { expect { parse_config }.to raise_error 'Invalid value for rabbitmq config raise_exceptions: "unvalid"' }
    end

    context 'without set routes file' do
      let(:settings) { {'test' => {uri: 'test'}} }

      it 'uses a default' do
        expect(parse_config[:routing_file]).to eq Rails.root.join('config/msgr.rb').to_s
      end
    end

    context 'with set routes file' do
      let(:settings) { {'test' => {uri: 'test', 'routing_file' => 'my fancy file'}} }

      it 'respects the override' do
        expect(parse_config[:routing_file]).to eq 'my fancy file'
      end
    end

    context 'with uri as symbol' do
      let(:settings) { {'test' => {uri: 'hans'}} }

      it 'uses the value' do
        expect(parse_config[:uri]).to eq 'hans'
      end
    end

    context 'with uri as string' do
      let(:settings) { {'test' => {'uri' => 'hans'}} }

      it 'uses the value' do
        expect(parse_config[:uri]).to eq 'hans'
      end
    end

    context 'without raise_exceptions config' do
      let(:settings) { {'test' => {'uri' => 'hans'}, 'development' => {'uri' => 'hans_dev'}} }

      it 'defaults to false' do
        expect(parse_config[:raise_exceptions]).to eq false
      end
    end
  end

  describe '#load' do
    let(:config) do
      cfg = ActiveSupport::OrderedOptions.new
      cfg.rabbitmq_config = Rails.root.join 'config', 'rabbitmq.yml'
      cfg
    end

    before do
      allow(Msgr).to receive(:start)
      allow(Msgr.client).to receive(:connect)
    end

    context 'with autostart is true' do
      it 'starts Msgr' do
        allow(described_class).to receive(:load_config).and_return('test' => {uri: 'test', autostart: true})
        described_class.load config
        expect(Msgr).to have_received(:start)
      end
    end

    context 'without autostart value' do
      it 'does not start Msgr' do
        allow(described_class).to receive(:load_config).and_return('test' => {uri: 'test'})
        described_class.load config
        expect(Msgr).not_to have_received(:start)
      end
    end

    context 'without checkcredentials value' do
      it 'connects to rabbitmq directly to check credentials' do
        allow(described_class).to receive(:load_config).and_return('test' => {uri: 'test'})
        described_class.load config
        expect(Msgr.client).to have_received(:connect)
      end
    end

    context 'with checkcredentials is false' do
      it 'connects to rabbitmq directly to check credentials' do
        allow(described_class).to receive(:load_config).and_return('test' => {uri: 'test', checkcredentials: false})
        described_class.load config
        expect(Msgr.client).not_to have_received(:connect)
      end
    end
  end

  # describe '#load_config'
  #   let(:options) { {} }

  #   subject { Msgr::Railtie.load_config options }

  #   if Rails::Application.methods.include(:config_for)
  #     it 'should use config_for' do

  #     end
  #   end
  # end
end
