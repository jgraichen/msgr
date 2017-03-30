require 'spec_helper'

class DispatcherTestConsumer < Msgr::Consumer
  def index
    puts "<<< #{payload}"
  end
end

class DispatcherRaiseConsumer < Msgr::Consumer
  def index
    raise ArgumentError, 'Not happy with the payload'
  end
end

describe Msgr::Dispatcher do
  let(:dispatcher) { described_class.new config }
  let(:config) { { max: 1 } }
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
       allow(ti).to receive(:delivery_tag).and_return(3)
    end
  end
  let(:payload) { {} }
  let(:metadata) do
    double(:metadata).tap do |metadata|
      allow(metadata).to receive(:content_type).and_return('text/plain')
    end
  end
  let(:message) { Msgr::Message.new connection, delivery_info, metadata, payload, route }
  let(:action) { -> { dispatcher.call message }}

  it 'should consume message' do
    expect_any_instance_of(DispatcherTestConsumer).to receive(:index)
    dispatcher.call message
  end

  context 'with not acknowledged message' do
    before { dispatcher.call message }
    subject { message }
    it { should be_acked }
  end

  describe 'exception swallowing' do
    let(:consumer) { 'DispatcherRaiseConsumer' }
    before do
      allow(message).to receive(:nack)
    end

    it 'should swallow exceptions by default' do
      expect { dispatcher.call(message) }.not_to raise_error
    end

    context 'with raise_exceptions configuration option and a synchronous pool' do
      let(:config) { super().merge(raise_exceptions: true) }

      it 'should raise the exception' do
        expect { dispatcher.call(message) }.to raise_error(ArgumentError)
      end
    end
  end
end
