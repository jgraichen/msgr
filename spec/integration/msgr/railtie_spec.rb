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
    subject { action }

    let(:settings) { {} }
    let(:action) { described_class.parse_config settings }

    context 'with incorrect settings' do
      subject { -> { action } }

      context 'with config without url' do
        let(:settings) { {'test' => {hans: 'otto'}} }

        it { is_expected.to raise_error 'Could not load rabbitmq environment config: URI missing.' }
      end

      context 'with invalid autostart value' do
        let(:settings) { {'test' => {uri: 'hans', autostart: 'unvalid'}} }

        it { is_expected.to raise_error 'Invalid value for rabbitmq config autostart: "unvalid"' }
      end

      context 'with invalid checkcredentials value' do
        let(:settings) { {'test' => {uri: 'hans', checkcredentials: 'unvalid'}} }

        it { is_expected.to raise_error 'Invalid value for rabbitmq config checkcredentials: "unvalid"' }
      end

      context 'with invalid raise_exceptions value' do
        let(:settings) { {'test' => {uri: 'franz', raise_exceptions: 'unvalid'}} }

        it { is_expected.to raise_error 'Invalid value for rabbitmq config raise_exceptions: "unvalid"' }
      end
    end

    context 'without set routes file' do
      let(:settings) { {'test' => {uri: 'test'}} }

      context '[:routing_file]' do
        subject { super()[:routing_file] }

        it { is_expected.to eq Rails.root.join('config/msgr.rb').to_s }
      end
    end

    context 'with set routes file' do
      let(:settings) { {'test' => {uri: 'test', 'routing_file' => 'my fancy file'}} }

      context '[:routing_file]' do
        subject { super()[:routing_file] }

        it { is_expected.to eq 'my fancy file' }
      end
    end

    context 'with uri as symbol' do
      let(:settings) { {'test' => {uri: 'hans'}} }

      context '[:uri]' do
        subject { super()[:uri] }

        it { is_expected.to eq 'hans' }
      end
    end

    context 'with uri as string' do
      let(:settings) { {'test' => {'uri' => 'hans'}} }

      context '[:uri]' do
        subject { super()[:uri] }

        it { is_expected.to eq 'hans' }
      end
    end

    context 'without raise_exceptions config' do
      let(:settings) { {'test' => {'uri' => 'hans'}, 'development' => {'uri' => 'hans_dev'}} }

      describe '[:raise_exceptions]' do
        subject { super()[:raise_exceptions] }

        it { is_expected.to eq false }
      end
    end
  end

  describe '#load' do
    let(:config) do
      cfg = ActiveSupport::OrderedOptions.new
      cfg.rabbitmq_config = Rails.root.join 'config', 'rabbitmq.yml'
      cfg
    end

    context 'with autostart is true' do
      it 'does not start Msgr' do
        expect(Msgr).to receive(:start)
        expect(described_class).to receive(:load_config).and_return('test' => {uri: 'test', autostart: true})
        described_class.load config
      end
    end

    context 'without autostart value' do
      it 'does not start Msgr' do
        expect(Msgr).not_to receive(:start)
        expect(described_class).to receive(:load_config).and_return('test' => {uri: 'test'})
        described_class.load config
      end
    end

    context 'without checkcredentials value' do
      it 'connects to rabbitmq directly to check credentials' do
        expect_any_instance_of(Msgr::Client).to receive(:connect)
        expect(described_class).to receive(:load_config).and_return('test' => {uri: 'test'})
        described_class.load config
      end
    end

    context 'with checkcredentials is false' do
      it 'connects to rabbitmq directly to check credentials' do
        expect_any_instance_of(Msgr::Client).not_to receive(:connect)
        expect(described_class).to receive(:load_config).and_return('test' => {uri: 'test', checkcredentials: false})
        described_class.load config
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
