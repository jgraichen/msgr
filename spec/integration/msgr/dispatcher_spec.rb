# frozen_string_literal: true

require 'spec_helper'

class DispatcherTestConsumer < Msgr::Consumer
  def index
    self.class.called!
  end

  class << self
    def calls
      @calls ||= 0
    end

    attr_writer :calls

    def called!
      self.calls += 1
    end
  end
end

class DispatcherRaiseConsumer < Msgr::Consumer
  def index
    raise ArgumentError.new('Not happy with the payload')
  end
end

describe Msgr::Dispatcher do
  let(:dispatcher) { described_class.new config }
  let(:config) { {max: 1} }
  let(:consumer) { 'DispatcherTestConsumer' }
  let(:route) do
    instance_double(Msgr::Route).tap do |t|
      allow(t).to receive_messages(consumer: consumer, action: 'index')
    end
  end
  let(:channel) do
    instance_double(Msgr::Channel).tap do |c|
      allow(c).to receive(:ack)
    end
  end
  let(:delivery_info) do
    instance_double(Bunny::DeliveryInfo).tap do |ti|
      allow(ti).to receive(:delivery_tag).and_return(3)
    end
  end
  let(:payload) { {} }
  let(:metadata) do
    instance_double(Bunny::MessageProperties).tap do |metadata|
      allow(metadata).to receive(:content_type).and_return('text/plain')
    end
  end
  let(:message) { Msgr::Message.new channel, delivery_info, metadata, payload, route }
  let(:action) { -> { dispatcher.call message } }

  it 'consumes message' do
    expect do
      dispatcher.call message
    end.to change(DispatcherTestConsumer, :calls).by(1)
  end

  context 'with not acknowledged message' do
    subject { message }

    before { dispatcher.call message }

    it { is_expected.to be_acked }
  end

  describe 'exception swallowing' do
    let(:consumer) { 'DispatcherRaiseConsumer' }

    before do
      allow(message).to receive(:nack)
    end

    it 'swallows exceptions by default' do
      expect { dispatcher.call(message) }.not_to raise_error
    end

    context 'with raise_exceptions configuration option and a synchronous pool' do
      let(:config) { super().merge(raise_exceptions: true) }

      it 'raises the exception' do
        expect { dispatcher.call(message) }.to raise_error(ArgumentError)
      end
    end
  end
end
