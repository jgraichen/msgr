require 'spec_helper'

class DispatcherTestConsumer < Msgr::Consumer
  def index
    puts "<<< #{payload}"
  end
end

describe Msgr::Dispatcher do
  let(:dispatcher) { described_class.new max: 1 }
  let(:consumer) { 'DispatcherTestConsumer' }
  let(:route) do
    double(:route).tap do |t|
      allow(t).to receive(:consumer).and_return consumer
      allow(t).to receive(:action).and_return 'index'
    end
  end
  let(:connection) do
    double(:connection).tap do |c|
      allow(c).to receive(:ack)
    end
  end
  let(:delivery_info) do
     double(:delivery_info).tap do |ti|
       allow(ti).to receive(:delivery_tag).and_return { 3 }
    end
  end
  let(:payload) { {} }
  let(:metadata) do
    double(:metadata).tap do |metadata|
      allow(metadata).to receive(:content_type).and_return { 'text/plain' }
    end
  end
  let(:message) { Msgr::Message.new connection, delivery_info, metadata, payload, route }
  let(:action) { -> { dispatcher.call message }}

  before do
    expect_any_instance_of(::Msgr::Dispatcher::NullPool).to receive(:post).and_return { |m, &block| block.call m}
    expect_any_instance_of(DispatcherTestConsumer).to receive(:index)
  end

  it 'should consume message' do
    dispatcher.call message
  end

  context 'with not acknowlged message' do
    before { dispatcher.call message }
    subject { message }
    it { should be_acked }
  end
end
