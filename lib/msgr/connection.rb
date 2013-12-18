module Msgr

  class Connection
    include Celluloid
    include Logging

    attr_reader :conn, :dispatcher, :routes, :opts
    finalizer :close

    def initialize(conn, routes, dispatcher, opts = {})
      @conn       = conn
      @dispatcher = dispatcher
      @routes     = routes
      @opts       = opts

      @channel = conn.create_channel
      @channel.prefetch(10)

      bind
    end

    def rebind
      release
      bind
    end

    def bind
      # Create new bindings
      routes.each { |route| bindings << Binding.new(Actor.current, route, dispatcher, exchange) }

      log(:debug) { 'New routes bound.' }
    end

    def prefix(name = '')
      opts[:prefix] ? "#{opts[:prefix]}-#{name}" : name
    end

    # Used to store al bindings. Allows use to
    # release bindings when receiver should not longer
    # receive messages but channel need to be open
    # to allow further acknowledgments.
    #
    def bindings
      @bindings ||= []
    end

    def queue(name)
      @channel.queue(prefix(name), durable: true).tap do |queue|
        log(:debug) { "Create queue #{queue.name} (durable: #{queue.durable?}, auto_delete: #{queue.auto_delete?})" }
      end
    end

    def exchange
      unless @exchange
        @exchange = @channel.topic prefix('msgr'), durable: true

        log(:debug) { "Created exchange #{@exchange.name} (type: #{@exchange.type}, durable: #{@exchange.durable?}, auto_delete: #{@exchange.auto_delete?})" }
      end

      @exchange
    end

    # Release all bindings but do not close channel. Will not
    # longer receive any message but channel can be used to
    # acknowledge currently processing messages.
    #
    def release(wait = false)
      return unless bindings.any?

      log(:debug) { "Release all bindings#{wait ? ' after queues are empty': ''}..." }

      if wait
        binds = bindings.dup
        while binds.any?
          binds.reject! { |b| b.release_if_empty }
          sleep 1
        end
      else
        bindings.each &:release
      end

      log(:debug) { 'All bindings released.' }
    end

    def delete
      return unless bindings.any?

      log(:debug) { 'Delete all bindings and exchange.' }

      bindings.each { |binding| binding.delete }
      bindings.clear

      @exchange.delete if @exchange
    end

    def publish(payload, opts = {})
      opts[:routing_key] ||= opts[:to]
      raise ArgumentError, 'Missing routing key.' unless opts[:routing_key]

      log(:debug) { "Publish message to #{opts[:routing_key]}" }

      begin
        payload = JSON.generate(payload)
        log(:debug) {opts.inspect}
        log(:debug) {exchange.name}
        exchange.publish payload, opts.merge(persistent: true, content_type: 'application/json')
      rescue => error
        exchange.publish payload.to_s, opts.merge(persistent: true, content_type: 'application/text')
      end
    end

    def ack(delivery_tag)
      log(:debug) { "Ack message: #{delivery_tag}" }
      @channel.ack delivery_tag
    end

    def reject(delivery_tag, requeue = true)
      log(:debug) { "Reject message: #{delivery_tag}" }
      @channel.reject delivery_tag, requeue
    end

    def close
      @channel.close if @channel.open?
      log(:debug) { 'Connection closed.' }
    end
  end
end
