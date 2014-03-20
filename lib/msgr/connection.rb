module Msgr

  class Connection
    include Logging

    EXCHANGE_NAME = 'msgr'

    attr_reader :uri, :config

    def initialize(uri, config, dispatcher)
      @uri        = uri
      @config     = config
      @dispatcher = dispatcher
    end

    def running?
      subscriptions.any?
    end

    def publish(payload, opts = {})
      opts[:routing_key] = opts.delete(:to) if opts[:to]

      begin
        payload = MultiJson.dump(payload)
        exchange.publish payload, opts.merge(persistent: true, content_type: 'application/json')
      rescue => error
        exchange.publish payload.to_s, opts.merge(persistent: true, content_type: 'application/text')
      end

      log(:debug) { "Published message to #{opts[:routing_key]}" }
    end

    def connection
      @connection ||= ::Bunny.new(config).tap { |b| b.start }
    end

    def channel
      @channel ||= connection.create_channel
    end

    def release
      subscriptions.each { |subscription| subscription.cancel }
    end

    def subscriptions
      @subscription ||= []
    end

    def prefix(name)
      if config[:prefix].present?
        "#{config[:prefix]}-#{name}"
      else
        name
      end
    end

    def exchange
      @exchange ||= channel.topic(prefix(EXCHANGE_NAME), durable: true).tap do |ex|
        log(:debug) do
          "Created exchange #{ex.name} (type: #{ex.type}, " \
              "durable: #{ex.durable?}, auto_delete: #{ex.auto_delete?})"
        end
      end
    end

    def queue(name)
      channel.queue(prefix(name), durable: true).tap do |queue|
        log(:debug) do
          "Create queue #{queue.name} (durable: #{queue.durable?}, " \
          "auto_delete: #{queue.auto_delete?})"
        end
      end
    end

    def bind(routes)
      if routes.empty?
        log(:warn) { "No routes to bound to. Bind will have no effect. (#{routes.inspect})" }
      else
        bind_all(routes)
      end
    end

    def ack(delivery_tag)
      channel.ack delivery_tag
      log(:debug) { "Acked message: #{delivery_tag}" }
    end

    def reject(delivery_tag, requeue = true)
      channel.reject delivery_tag, requeue
      log(:debug) { "Rejected message: #{delivery_tag}" }
    end

    def close
      channel.close    if @channel && @channel.open?
      connection.close if @connection
      log(:debug) { 'Closed.' }
    end

    private
    def bind_all(routes)
      routes.each do |route|
        queue = queue(route.name)

        route.keys.each do |key|
          log(:debug) { "Bind #{key} to #{queue.name}." }

          queue.bind exchange, routing_key: key
        end

        subscriptions << queue.subscribe(ack: true) do |*args|
          begin
            @dispatcher.call Message.new(self, *args, route)
          rescue => err
            log(:error) do
              "Rescued error from subscribe: #{err.class.name}: #{err}\n#{err.backtrace.join("\n")}"
            end
          end
        end
      end
    end
  end
end
