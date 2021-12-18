# frozen_string_literal: true

module Msgr
  class Channel
    include Logging

    EXCHANGE_NAME = 'msgr'

    attr_reader :config, :channel

    def initialize(config, connection)
      @config  = config
      @channel = connection.create_channel
    end

    def prefetch(count)
      @channel.prefetch count
    end

    def exchange
      @exchange ||= begin
        @channel.topic(prefix(EXCHANGE_NAME), durable: true).tap do |ex|
          log(:debug) do
            "Created exchange #{ex.name} (type: #{ex.type}, " \
              "durable: #{ex.durable?}, auto_delete: #{ex.auto_delete?})"
          end
        end
      end
    end

    def queue(name, **opts)
      @channel.queue(prefix(name), durable: true, **opts).tap do |queue|
        log(:debug) do
          "Create queue #{queue.name} (durable: #{queue.durable?}, " \
            "auto_delete: #{queue.auto_delete?})"
        end
      end
    end

    def prefix(name)
      if config[:prefix].present?
        "#{config[:prefix]}-#{name}"
      else
        name
      end
    end

    def ack(delivery_tag)
      @channel.ack delivery_tag
      log(:debug) { "Acked message: #{delivery_tag}" }
    end

    def nack(delivery_tag)
      @channel.nack delivery_tag, false, true
      log(:debug) { "Nacked message: #{delivery_tag}" }
    end

    def reject(delivery_tag, requeue = true)
      @channel.reject delivery_tag, requeue
      log(:debug) { "Rejected message: #{delivery_tag}" }
    end

    def close
      @channel.close if @channel.open?
    end
  end
end
