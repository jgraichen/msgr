# frozen_string_literal: true

require 'spec_helper'

describe Msgr::Routes do
  let(:routes) { Msgr::Routes.new }

  describe '#configure' do
    let(:block) { proc {} }

    it 'should evaluate given block within instance context' do
      expect(routes).to receive(:instance_eval) do |&p|
        expect(p).to be block
      end

      routes.configure(&block)
    end

    it 'should allow to call instance method in gven block' do
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

    it 'should iterate over configured routes' do
      expect(each.size).to eq 2

      expect(each.map(&:keys)).to eq [%w[abc.#], %w[edf.#]]
      expect(each.map(&:consumer)).to eq %w[TestConsumer TestConsumer]
      expect(each.map(&:action)).to eq %w[index action]
    end
  end

  describe '#route' do
    let(:subject) { -> { routes.route 'routing.key', to: 'test2#index2' } }
    let(:last_route) { routes.routes.last }

    it 'should add a new route' do
      expect { subject.call }.to change { routes.routes.size }.from(0).to(1)
    end

    it 'should add given route' do
      subject.call

      expect(last_route.keys).to eq %w[routing.key]
      expect(last_route.consumer).to eq 'Test2Consumer'
      expect(last_route.action).to eq 'index2'
    end

    context 'with same target' do
      let(:subject) do
        lambda do
          routes.route 'routing.key', to: 'test#index'
          routes.route 'another.routing.key', to: 'test#index'
        end
      end

      it 'should only add one new route' do
        expect { subject.call }.to change { routes.routes.size }.from(0).to(1)
      end

      it 'should add second binding to first route' do
        subject.call
        expect(routes.routes.first.keys).to eq %w[routing.key another.routing.key]
      end
    end
  end

  describe '#files' do
    it 'should allow to add route paths' do
      routes.files << 'abc.rb'
      routes.files += %w[cde.rb edf.rb]

      expect(routes.files).to eq %w[abc.rb cde.rb edf.rb]
    end
  end

  describe 'reload' do
    before { File.stub(:exist?).and_return(true) }

    it 'should trigger load for all files' do
      expect(routes).to receive(:load).with('cde.rb').ordered
      expect(routes).to receive(:load).with('edf.rb').ordered
      routes.files += %w[cde.rb edf.rb]
      routes.reload
    end

    it 'should clear old routes before reloading' do
      routes.route 'abc', to: 'abc#test'
      routes.reload
      expect(routes.each.size).to eq 0
    end
  end

  describe 'load' do
    let(:file) { 'spec/fixtures/msgr-routes-test-1.rb' }

    it 'should eval given file within routes context' do
      expect(routes).to receive(:route).with('abc.#', to: 'test#index')
      routes.load file
    end
  end
end
