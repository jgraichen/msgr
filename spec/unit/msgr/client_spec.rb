# frozen_string_literal: true

require 'spec_helper'

describe Msgr::Client do
  subject(:client) { described_class.new config }

  let(:config) { {} }

  describe '#uri' do
    subject(:uri) { client.uri.to_s }

    context 'with default config' do
      it 'uses the default config' do
        expect(uri).to eq 'amqp://127.0.0.1'
      end
    end

    context 'without vhost' do
      let(:config) { {uri: 'amqp://rabbit'} }

      it 'does not specify a vhost' do
        expect(uri).to eq 'amqp://rabbit'
      end
    end

    context 'with empty vhost' do
      let(:config) { {uri: 'amqp://rabbit/'} }

      it 'does not specify a vhost' do
        expect(uri).to eq 'amqp://rabbit'
      end
    end

    context 'with explicit vhost' do
      let(:config) { {uri: 'amqp://rabbit/some_vhost'} }

      # This behavior is due to legacy parsing in Msgr's config.
      # We interpret the entire path (incl. the leading slash)
      # as vhost. As per AMQP rules, this means the leading slash
      # is part of the vhost, which means it has to be URL encoded.
      # This will likely change with the next major release.
      it 'uses the entire path as vhost' do
        expect(uri).to eq 'amqp://rabbit/%2Fsome_vhost'
      end
    end

    context 'with URI and vhost' do
      let(:config) { {uri: 'amqp://rabbit/some_vhost', vhost: 'real_vhost'} }

      # This is currently the only way to specify a vhost without
      # leading slash (as a vhost in the :uri config would have
      # an extra URL encoded leading slash).
      it 'uses the explicit vhost' do
        expect(uri).to eq 'amqp://rabbit/real_vhost'
      end
    end
  end

  describe 'drain' do
    subject(:drain) { client.drain }

    let(:config) { {routing_file: 'spec/fixtures/msgr_routes_test_drain.rb'} }
    let(:channel_stub) { instance_double('Msgr::Channel', prefetch: true) }
    let(:queue_stub) { instance_double('Bunny::Queue', purge: true) }

    before do
      allow(Msgr::Channel).to receive(:new).and_return(channel_stub)
      allow(channel_stub).to receive(:queue).and_return(queue_stub).at_most(3).times
    end

    it 'requests purges for all configured routes' do
      drain

      expect(Msgr::Channel).to have_received(:new).exactly(3).times
      expect(channel_stub).to have_received(:queue).with('msgr.consumer.Consumer1Consumer.action1', passive: true).once
      expect(channel_stub).to have_received(:queue).with('msgr.consumer.Consumer1Consumer.action2', passive: true).once
      expect(channel_stub).to have_received(:queue).with('msgr.consumer.Consumer2Consumer.action1', passive: true).once

      expect(queue_stub).to have_received(:purge).exactly(3).times
    end
  end
end
