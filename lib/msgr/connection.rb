require 'bunny'
require 'multi_json'

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
      bindings.any?
    end

    def publish(message, opts = {})
      opts[:routing_key] = opts.delete(:to) if opts[:to]

      exchange.publish message.to_s, opts.merge(persistent: true)

      log(:debug) { "Published message to #{opts[:routing_key]}" }
    end

    def connection
      @connection ||= ::Bunny.new(config).tap { |b| b.start }
    end

    def connect
      connection
    end

    def channel
      @channel ||= begin
        channel = connection.create_channel
        channel.prefetch 10
        channel
      end
    end

    def release
      return if bindings.empty?
      log(:debug) { "Release bindings (#{bindings.size})..." }

      bindings.each { |binding| binding.release }
    end

    def delete
      return if bindings.empty?
      log(:debug) { "Delete bindings (#{bindings.size})..." }

      bindings.each { |binding| binding.delete }
      exchange.delete
    end

    def bindings
      @bindings ||= []
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

    def nack(delivery_tag)
      channel.nack delivery_tag, false, true
      log(:debug) { "Nacked message: #{delivery_tag}" }
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
      routes.each { |route| bindings << Binding.new(self, route, @dispatcher) }
    end
  end
end
