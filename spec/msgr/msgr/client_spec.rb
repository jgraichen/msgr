require 'spec_helper'

describe Msgr::Client do

  describe '#start' do
    let(:params) { [] }
    let(:client) { Msgr::Client.new *params }
    before { allow_any_instance_of(Msgr::Client).to receive(:launch) }

    context 'with URI' do
      it 'should pass URI options to bunny (I)' do
        expect(Bunny).to receive(:new)
                         .with(pass: 'guest', user: 'guest', ssl: false, host: 'localhost', vhost: '/')

        Msgr::Client.new(uri: 'amqp://guest:guest@localhost/').start
      end

      it 'should pass URI options to bunny (II)' do
        expect(Bunny).to receive(:new)
                         .with(pass: 'msgr', user: 'abc', ssl: true, host: 'bogus.example.org', vhost: '/rabbit')

        Msgr::Client.new(uri: 'amqps://abc:msgr@bogus.example.org/rabbit').start
      end
    end

    context 'with options' do
      it 'should pass options to bunny' do
        expect(Bunny).to receive(:new)
                         .with(pass: 'guest', user: 'guest', ssl: false, host: 'localhost', vhost: '/')

        Msgr::Client.new(pass: 'guest', user: 'guest', ssl: false, host: 'localhost', vhost: '/').start
      end
    end

    context 'with URI and options' do
      it 'should pass merged options to bunny' do
        expect(Bunny).to receive(:new)
                         .with(pass: 'msgr', user: 'abc', ssl: false, host: 'localhost', vhost: '/joghurt')

        Msgr::Client.new(uri: 'ampq://abc@localhost', pass: 'msgr', vhost: '/joghurt').start
      end

      it 'should pass prefer hash option' do
        expect(Bunny).to receive(:new)
                         .with(ssl: true, host: 'a.example.org', vhost: '/', user: 'guest')

        Msgr::Client.new(uri: 'ampq://localhost', ssl: true, host: 'a.example.org').start
      end
    end

    context 'routes' do
      let(:params) { [ routing_file: 'config/msgr.rb']}
      before { client.start }
      subject { client.routes }
      its(:files) { should eq ['config/msgr.rb'] }
    end
  end
end
