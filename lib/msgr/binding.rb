module Msgr
  # A single binding
  class Binding
    attr_reader :connection, :route, :subscription

    def initialize(connection, route)
      @connection = connection
      @route      = route

      queue    = connection.queue route.name

      queue.bind connection.exchange, routing_key: route.key

      @subscription = queue.subscribe ack: true, &method(:call)
    end

    def call(info, metadata, payload)
      message = Message.new(connection, info, metadata, payload, route)
      connection.dispatch message
    rescue => error
      Msgr.logger.warn(self) { "Error received within bunny subscribe handler: #{error.inspect}." }
    end

    def release
      subscription.cancel if subscription
    end
  end
end
