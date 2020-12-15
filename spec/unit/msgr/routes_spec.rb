# frozen_string_literal: true

require 'spec_helper'

describe Msgr::Routes do
  let(:routes) { described_class.new }

  describe '#configure' do
    let(:block) { proc {} }

    it 'evaluates given block within instance context' do
      expect(routes).to receive(:instance_eval) do |&p|
        expect(p).to be block
      end

      routes.configure(&block)
    end

    it 'allows to call instance method in gven block' do
      expect(routes).to receive(:test_instance_method).with(:abc)

      routes.configure do
        test_instance_method :abc
      end
    end
  end

  describe '#each' do
    before do
      routes.configure do
        route 'abc.#', to: 'test#index'
        route 'edf.#', to: 'test#action'
      end
    end

    let(:each) { routes.each }

    it 'iterates over configured routes' do
      expect(each.size).to eq 2

      expect(each.map(&:keys)).to eq [%w[abc.#], %w[edf.#]]
      expect(each.map(&:consumer)).to eq %w[TestConsumer TestConsumer]
      expect(each.map(&:action)).to eq %w[index action]
    end
  end

  describe '#route' do
    subject(:route) { -> { routes.route 'routing.key', to: 'test2#index2' } }

    let(:last_route) { routes.routes.last }

    it 'adds a new route' do
      expect { route.call }.to change { routes.routes.size }.from(0).to(1)
    end

    it 'adds given route' do
      route.call

      expect(last_route.keys).to eq %w[routing.key]
      expect(last_route.consumer).to eq 'Test2Consumer'
      expect(last_route.action).to eq 'index2'
    end

    context 'with same target' do
      subject(:route) do
        lambda do
          routes.route 'routing.key', to: 'test#index'
          routes.route 'another.routing.key', to: 'test#index'
        end
      end

      it 'onlies add one new route' do
        expect { route.call }.to change { routes.routes.size }.from(0).to(1)
      end

      it 'adds second binding to first route' do
        route.call
        expect(routes.routes.first.keys).to eq %w[routing.key another.routing.key]
      end
    end
  end

  describe '#files' do
    it 'allows to add route paths' do
      routes.files << 'abc.rb'
      routes.files += %w[cde.rb edf.rb]

      expect(routes.files).to eq %w[abc.rb cde.rb edf.rb]
    end
  end

  describe 'reload' do
    before { File.stub(:exist?).and_return(true) }

    it 'triggers load for all files' do
      expect(routes).to receive(:load).with('cde.rb').ordered
      expect(routes).to receive(:load).with('edf.rb').ordered
      routes.files += %w[cde.rb edf.rb]
      routes.reload
    end

    it 'clears old routes before reloading' do
      routes.route 'abc', to: 'abc#test'
      routes.reload
      expect(routes.each.size).to eq 0
    end
  end

  describe 'load' do
    let(:file) { 'spec/fixtures/msgr_routes_test_1.rb' }

    it 'evals given file within routes context' do
      expect(routes).to receive(:route).with('abc.#', to: 'test#index')
      routes.load file
    end
  end
end
