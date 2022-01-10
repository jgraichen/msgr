# frozen_string_literal: true

require 'spec_helper'

describe Msgr::Route do
  subject { route }

  let(:routing_key) { 'routing.key.#' }
  let(:options) { {to: 'test#index'} }
  let(:args) { [routing_key, options] }
  let(:route) { described_class.new(*args) }

  describe '#initialize' do
    it 'requires `to` option' do
      expect do
        described_class.new(routing_key, {})
      end.to raise_error(ArgumentError)
    end

    it 'requires routing_key' do
      expect do
        described_class.new nil, options
      end.to raise_error(ArgumentError)
    end

    it 'requires not empty routing_key' do
      expect do
        described_class.new '', options
      end.to raise_error ArgumentError, /routing key required/i
    end

    it 'requires `to: "consumer#action` format' do
      expect do
        described_class.new routing_key, to: 'abc'
      end.to raise_error ArgumentError, /invalid consumer format/i
    end

    it 'allows namespaces in consumer' do
      expect do
        described_class.new routing_key, to: 'abc/def#ghi'
      end.not_to raise_error
    end
  end

  describe '#consumer' do
    it 'returns consumer class name' do
      expect(route.consumer).to eq 'TestConsumer'
    end

    context 'with underscore consumer name' do
      let(:options) { super().merge to: 'test_resource_foo#index' }

      it 'returns camelized class name' do
        expect(route.consumer).to eq 'TestResourceFooConsumer'
      end
    end

    context 'with nested namespace in consumer name' do
      let(:options) { super().merge to: 'nested/namespace/foo#index' }

      it 'returns fully classified, classified class name' do
        expect(route.consumer).to eq 'Nested::Namespace::FooConsumer'
      end
    end
  end

  describe '#action' do
    it 'returns action method name' do
      expect(route.action).to eq 'index'
    end

    context 'with camelCase action name' do
      let(:options) { super().merge to: 'test#myActionMethod' }

      it 'returns underscore method name' do
        expect(route.action).to eq 'my_action_method'
      end
    end
  end
end
