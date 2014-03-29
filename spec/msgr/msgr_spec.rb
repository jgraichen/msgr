require 'spec_helper'

class Receiver
end

#
class MsgrTestConsumer < Msgr::Consumer
  def index
    Receiver.index
  end

  def error
    Receiver.error
  end
end

describe Msgr do
  before do
    Msgr.logger = nil
    Msgr.logger.level = Logger::Severity::DEBUG if Msgr.logger
  end

  let(:queue) { Queue.new }
  let(:client) { Msgr::Client.new size: 1, prefix: SecureRandom.hex(2) }

  before do
    client.routes.configure do
      route 'test.index', to: 'msgr_test#index'
      route 'test.error', to: 'msgr_test#error'
    end

    client.start
  end

  after do
    client.stop delete: true
  end

  it 'should dispatch published methods to consumer' do
    expect(Receiver).to receive(:index) { queue << :end }

    client.publish 'Payload', to: 'test.index'

    Timeout::timeout(4) { queue.pop }
  end

  it 'should redelivery failed messages' do
    expect(Receiver).to receive(:error).ordered.and_raise RuntimeError
    expect(Receiver).to receive(:error).ordered { queue << :end }

    client.publish 'Payload', to: 'test.error'

    Timeout::timeout(4) { queue.pop }
  end
end
