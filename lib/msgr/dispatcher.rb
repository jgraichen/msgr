require 'concurrent/cached_thread_pool'

module Msgr

  # The Dispatcher receives incoming messages,
  # process them through a middleware stack and
  # delegate them to a new and fresh consumer instance.
  #
  class Dispatcher
    include Logging

    attr_reader :pool

    def initialize(config)
      log(:info) { "Initialize new dispatcher (#{config[:max]} threads)..." }

      @pool = ::Concurrent::CachedThreadPool.new(max: config[:max])
    end

    def call(message)
      pool.post(message) do |message|
        dispatch message
      end
    end

    def dispatch(message)
      consumer_class = Object.const_get message.route.consumer

      log(:debug) { "Dispatch message to #{consumer_class.name}" }

      consumer_class.new.dispatch message

      # Acknowledge message unless it is already acknowledged.
      message.ack unless message.acked?
    rescue => error
      log(:error) do
        "Dispatcher error: #{error.class.name}: #{error}\n" +
            error.backtrace.join("\n")
      end
    end

    def shutdown

    end

    def to_s
      self.class.name
    end
  end
end
