module Msgr

  class Connection
    include Celluloid
    include Logging

    attr_reader :conn, :pool, :routes
    finalizer :close

    def initialize(conn, routes, pool)
      @conn   = conn
      @pool   = pool
      @routes = routes

      @channel = conn.create_channel
      @channel.prefetch(10)

      rebind
    end

    def rebind(routes = nil)
      routes = self.routes unless routes

      # First release old bindings
      release

      # Create new bindings
      routes.each { |route| bindings << Binding.new(Actor.current, route) }

      log(:debug) { 'New routes bound.' }
    end

    # Used to store al bindings. Allows use to
    # release bindings when receiver should not longer
    # receive messages but channel need to be open
    # to allow further acknowledgments.
    #
    def bindings
      @bindings ||= []
    end

    # Will be called by Binding when a message is received.
    #
    # @param [Message] message Received message.
    #
    def dispatch(message)
      pool.dispatch :call, message
    end

    def queue(name)
      @channel.queue name, durable: true
    end

    def exchange
      @exchange ||= @channel.topic 'msgr', durable: true
    end

    # Release all bindings but do not close channel. Will not
    # longer receive any message but channel can be used to
    # acknowledge currently processing messages.
    #
    def release
      return unless bindings.any?

      log(:debug) { 'Release all bindings.' }

      bindings.each { |binding| binding.release }
      bindings.clear
    end

    def publish(payload, opts = {})
      exchange.publish payload, opts.merge(persistent: true)
    end

    def ack(delivery_tag)
      @channel.ack delivery_tag
    end

    def close
      @channel.close if @channel.open?
      log(:debug) { 'Connection closed.' }
    end
  end
end
