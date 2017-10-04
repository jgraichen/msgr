# frozen_string_literal: true

require 'spec_helper'

describe Msgr::Route do
  let(:routing_key) { 'routing.key.#' }
  let(:options) { {to: 'test#index'} }
  let(:args) { [routing_key, options] }
  let(:route) { Msgr::Route.new(*args) }
  subject { route }

  describe '#initialize' do
    it 'should require `to` option' do
      expect do
        Msgr::Route.new(routing_key, {})
      end.to raise_error(ArgumentError)
    end

    it 'should require routing_key' do
      expect do
        Msgr::Route.new nil, options
      end.to raise_error(ArgumentError)
    end

    it 'should require not empty routing_key' do
      expect do
        Msgr::Route.new '', options
      end.to raise_error ArgumentError, /routing key required/i
    end

    it 'should require `to: "consumer#action` format' do
      expect do
        Msgr::Route.new routing_key, to: 'abc'
      end.to raise_error ArgumentError, /invalid consumer format/i
    end
  end

  describe '#consumer' do
    it 'should return consumer class name' do
      expect(route.consumer).to eq 'TestConsumer'
    end

    context 'with underscore consumer name' do
      let(:options) { super().merge to: 'test_resource_foo#index' }

      it 'should return camelized method name' do
        expect(route.consumer).to eq 'TestResourceFooConsumer'
      end
    end
  end

  describe '#action' do
    it 'should return action method name' do
      expect(route.action).to eq 'index'
    end

    context 'with camelCase action name' do
      let(:options) { super().merge to: 'test#myActionMethod' }

      it 'should return underscore method name' do
        expect(route.action).to eq 'my_action_method'
      end
    end
  end
end
