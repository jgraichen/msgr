require 'spec_helper'

class TestConsumer < Msgr::Consumer
  def index
    puts "<<< #{payload}"
  end
end

describe Msgr do
  before do
    Msgr.logger = nil;
    Msgr.logger.level = Logger::Severity::DEBUG if Msgr.logger
  end

  let(:client) { Msgr::Client.new size: 1, prefix: SecureRandom.hex(32) }

  before do
    client.routes.configure do
      route '#', to: 'test#index'
    end

    client.start
  end

  after do
    client.stop timeout: 10, delete: true, wait_empty: true
  end

  it 'should dispatch published methods to consumer' do
    expect_any_instance_of(TestConsumer).to receive(:index).within(10).seconds.and_call_original

    client.publish 'routing.key', 'Payload'

    sleep 10
  end
end
