# frozen_string_literal: true

require 'bunny'

module Msgr
  class Connection
    include Logging

    attr_reader :uri, :config

    def initialize(uri, config, dispatcher)
      @uri        = uri
      @config     = config
      @dispatcher = dispatcher
      @channels   = []
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
      @connection ||= ::Bunny.new(config).tap(&:start)
    end

    def connect
      connection
    end

    def channel(prefetch: 1)
      channel = Msgr::Channel.new(config, connection)
      channel.prefetch(prefetch)
      @channels << channel
      channel
    end

    def exchange
      @exchange ||= channel.exchange
    end

    def release
      return if bindings.empty?

      log(:debug) { "Release bindings (#{bindings.size})..." }

      bindings.each(&:release)
    end

    def delete
      return if bindings.empty?

      log(:debug) { "Delete bindings (#{bindings.size})..." }

      bindings.each(&:delete)
    end

    def purge(**kwargs)
      return if bindings.empty?

      log(:debug) { "Purge bindings (#{bindings.size})..." }

      bindings.each {|b| b.purge(**kwargs) }
    end

    def purge_queue(name)
      # Creating the queue in passive mode ensures that queues that do not exist
      # won't be created just to purge them.
      # That requires creating a new channel every time, as exceptions (on
      # missing queues) invalidate the channel.
      channel.queue(name, passive: true).purge
    rescue Bunny::NotFound
      nil
    end

    def bindings
      @bindings ||= []
    end

    def bind(routes)
      if routes.empty?
        log(:warn) do
          "No routes to bound to. Bind will have no effect:\n" \
          "  #{routes.inspect}"
        end
      else
        bind_all(routes)
      end
    end

    def close
      @channels.each(&:close)
      connection.close if @connection
      log(:debug) { 'Closed.' }
    end

    private

    def bind_all(routes)
      routes.each {|route| bindings << Binding.new(self, route, @dispatcher) }
    end
  end
end
