require 'spec_helper'

describe Msgr::Routes do
  let(:routes) { Msgr::Routes.new }

  describe '#configure' do
    let(:block) { Proc.new{} }

    it 'should evaluate given block within instance context' do
      expect(routes).to receive(:instance_eval).with { |p| p == block }

      routes.configure &block
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
        route 'edf.#', to: 'test#index'
      end
    end

    let(:each) { routes.each }

    it 'should iterate over configured routes' do
      expect(each).to have(2).items

      expect(each.map(&:routing_key)).to be == %w(abc.# edf.#)
      expect(each.map(&:consumer)).to be == %w(TestConsumer TestConsumer)
      expect(each.map(&:action)).to be == %w(index index)
    end
  end

  describe '#route' do
    let(:subject) { -> { routes.route 'routing.key', to: 'test2#index2' } }
    let(:last_route) { routes.routes.last }

    it 'should add a new route' do
      expect { subject.call }.to change{ routes.routes.size }.from(0).to(1)
    end

    it 'should add given route' do
      subject.call

      expect(last_route.routing_key).to eq 'routing.key'
      expect(last_route.consumer).to eq 'Test2Consumer'
      expect(last_route.action).to eq 'index2'
    end
  end
end
