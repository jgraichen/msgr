module Msgr
  # A single binding
  class Binding
    include Logging
    attr_reader :connection, :route, :subscription, :dispatcher, :queue

    def initialize(connection, route, dispatcher)
      @connection = connection
      @route      = route
      @dispatcher = dispatcher

      exchange  = connection.exchange
      @queue    = connection.queue route.name

      route.keys.each do |key|
        log(:debug) { "Bind #{key} to #{@queue.name}." }

        queue.bind exchange, routing_key: key
      end

      @subscription = queue.subscribe(ack: true) { |*args| call *args }
    end

    # Called from Bunny Thread Pool. Will create message object from
    # provided bunny data and dispatch message to connection.
    #
    def call(info, metadata, payload)
      message = Message.new(connection, info, metadata, payload, route)
      dispatcher.dispatch message

      unless message.acked?
        log(:warn) { 'Message dispatch done but message still no acked.' }
        message.ack
      end
    rescue => error
      log(:error) { "Error received within subscribe handler: #{error.inspect}." }
      message.reject
    end

    # Cancel subscription to not receive any more messages.
    #
    def release
      subscription.cancel if subscription
    end

    def release_if_empty
      if queue_empty?
        release
        true
      else
        false
      end
    end

    def queue_empty?
      @queue.message_count == 0
    end

    def delete
      release
      queue.delete
    end

    def purge
      queue.purge
    end
  end
end
