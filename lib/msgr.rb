require 'msgr/version'
require 'active_support'
require 'celluloid'
require 'bunny'

require 'msgr/bindings'
require 'msgr/client'
require 'msgr/errors'
require 'msgr/worker'

require 'msgr/railtie' if defined?(Rails::Railtie)

class TestConsumer

end

module Msgr

  class << self
    def bunny

    end

    def start
      @client ||= Client.new uri: 'amqp://msgr:msgr@localhost'

      @client.bindings.configure do
        route '#', to: 'test#index'
      end

      @client.start

      1000.times { @client.publish 'ABC', routing_key: 'io.msgr.test' }

      @client.join

      #@bunny = Bunny.new 'amqp://msgr:msgr@localhost'
      #@bunny.start
      #@channel = @bunny.create_channel
      #@queue = @channel.queue 'msgr.test.queue'
      #@exchange = @channel.topic 'msgr.test.topic'
      #@queue.bind(@exchange, routing_key: '#').subscribe(ack: true) do |delivery_info, metadata, payload|
      #  pool.async.process [delivery_info, metadata, payload]
      #end
    end

    def publish(route, payload)
      @client.publish payload, routing_key: route
      nil
    end
  end
end
