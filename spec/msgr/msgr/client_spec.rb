# frozen_string_literal: true
require 'spec_helper'

describe Msgr::Client do
  subject { described_class.new config }
  let(:config) { {} }

  describe '#uri' do
    subject { super().uri.to_s }

    context 'with default config' do
      it 'uses the default config' do
        is_expected.to eq 'amqp://127.0.0.1'
      end
    end

    context 'with overwritten URI' do
      context 'without vhost' do
        let(:config) { {uri: 'amqp://rabbit'} }

        it 'does not specify a vhost' do
          is_expected.to eq 'amqp://rabbit'
        end
      end

      context 'with empty vhost' do
        let(:config) { {uri: 'amqp://rabbit/'} }

        it 'does not specify a vhost' do
          is_expected.to eq 'amqp://rabbit'
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
          is_expected.to eq 'amqp://rabbit/%2Fsome_vhost'
        end
      end
    end

    context 'with URI and vhost' do
      let(:config) { {uri: 'amqp://rabbit/some_vhost', vhost: 'real_vhost'} }

      # This is currently the only way to specify a vhost without
      # leading slash (as a vhost in the :uri config would have
      # an extra URL encoded leading slash).
      it 'uses the explicit vhost' do
        is_expected.to eq 'amqp://rabbit/real_vhost'
      end
    end
  end
end
