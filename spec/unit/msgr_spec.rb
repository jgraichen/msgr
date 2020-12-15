# frozen_string_literal: true

require 'spec_helper'

class Receiver
end

class MsgrTestConsumer < Msgr::Consumer
  def index
    Receiver.index
  end

  def error
    Receiver.error
  end
end

class MsgrPrefetchTestConsumer < Msgr::Consumer
  self.auto_ack = false

  def index
    Receiver.batch message
  end
end

describe Msgr do
  let(:queue) { Queue.new }
  let(:client) { Msgr::Client.new size: 1, prefix: SecureRandom.hex(2), uri: ENV['AMQP_SERVER'] }

  before do
    client.routes.configure do
      route 'test.index', to: 'msgr_test#index'
      route 'test.error', to: 'msgr_test#error'
      route 'test.batch', to: 'msgr_prefetch_test#index', prefetch: 2
    end

    client.start

    allow(Receiver).to receive(:index) { queue << :end }
    allow(Receiver).to receive(:batch) {|msg| queue << msg }

    error_count = 0
    allow(Receiver).to receive(:error) do
      error_count += 1
      raise 'error' if error_count == 1

      queue << :end
    end
  end

  after do
    client.stop delete: true
  end

  it 'dispatches published methods to consumer' do
    client.publish 'Payload', to: 'test.index'

    Timeout.timeout(4) { queue.pop }

    expect(Receiver).to have_received(:index).exactly(1).time
  end

  it 'redelivers failed messages' do
    client.publish 'Payload', to: 'test.error'

    Timeout.timeout(4) { queue.pop }

    expect(Receiver).to have_received(:error).exactly(2).times
  end

  it 'receives 2 messages when prefetch is set to 2' do
    2.times { client.publish 'Payload', to: 'test.batch' }

    2.times { Timeout.timeout(4) { queue.pop } }

    expect(Receiver).to have_received(:batch).exactly(2).times
  end

  it 'does not bulk ack all unacknowledged messages when acknowledging the last one' do
    2.times { client.publish 'Payload', to: 'test.batch' }

    messages = Array.new(2) { Timeout.timeout(4) { queue.pop } }
    messages[1].ack
    messages[0].nack

    # Test whether the nacked message gets redelivered. In this case, it was not acked when acknowledging the other message
    message = Timeout.timeout(4) { queue.pop }
    expect(message.payload).to eq(messages[0].payload)
    expect(message.delivery_info.redelivered).to eq(true)

    expect(Receiver).to have_received(:batch).exactly(3).times
  end
end
