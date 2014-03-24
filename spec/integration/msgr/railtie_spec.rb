require 'spec_helper'

describe Msgr::Railtie do

  describe 'configuration options' do
    let(:config) { Rails.configuration }

    it 'should have `msgr` key' do
      expect(config).to respond_to :msgr
    end
  end

  describe '#parse_config' do
    let(:settings) { {} }
    let(:action) { described_class.parse_config settings }
    subject { action }

    context 'with incorrect settings' do
      subject { -> { action } }

      context 'with config without url' do
        let(:settings) { {"test" => { hans: 'otto'}} }

        it { should raise_error 'Could not load rabbitmq environment config: URI missing.' }
      end

      context 'with invalid autostart value' do
        let(:settings) { {"test" => { uri: 'hans', autostart: 'unvalid'}} }

        it { should raise_error 'Invalid value for rabbitmq config autostart: "unvalid"'}
      end
    end

    context 'without set routes file' do
      let(:settings) { {"test" => { uri: 'test'}} }

      its([:routing_file]) { should eq Rails.root.join('config/msgr.rb').to_s }
    end

    context 'with set routes file' do
      let(:settings) { {"test" => { uri: 'test', 'routing_file' => 'my fancy file' }} }

      its([:routing_file]) { should eq 'my fancy file' }
    end

    context 'with uri as symbol' do
      let(:settings) { {"test" => { uri: "hans"}}}

      its([:uri]) { should eq 'hans' }
    end

    context 'with uri as string' do
      let(:settings) { {"test" => { 'uri' => "hans"}}}

      its([:uri]) { should eq 'hans' }
    end
  end

  describe '#load' do
    let(:config) do
      cfg = ActiveSupport::OrderedOptions.new
      cfg.rabbitmq_config = Rails.root.join *%w(config rabbitmq.yml)
      cfg
    end

    context 'with autostart is true' do
      it 'should not start Msgr' do
        expect(Msgr).to receive(:start)
        expect(Msgr::Railtie).to receive(:load_config).and_return({ "test" => { uri: 'test', autostart: true} })
        Msgr::Railtie.load config
      end
    end

    context 'without autostart value' do
      it 'should not start Msgr' do
        expect(Msgr).to_not receive(:start)
        expect(Msgr::Railtie).to receive(:load_config).and_return({ "test" => { uri: 'test' } })
        Msgr::Railtie.load config
      end
    end
  end
end
