module Msgr

  # The Dispatcher receives incoming messages,
  # process them through a middleware stack and
  # delegate them to a new and fresh consumer instance.
  #
  class Dispatcher
    include Logging

    attr_reader :config, :pool

    def initialize(config)
      config[:pool_class] ||= 'Msgr::Dispatcher::NullPool'

      log(:debug) { "Initialize new dispatcher (#{config[:pool_class]}: #{config})..." }

      @config = config
      @pool = config[:pool_class].constantize.new config
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
      message.nack unless message.acked?

      log(:error) do
        "Dispatcher error: #{error.class.name}: #{error}\n" +
            error.backtrace.join("\n")
      end

      raise error if config[:raise_exceptions]
    ensure
      if defined?(ActiveRecord) && ActiveRecord::Base.connection_pool.active_connection?
        log(:debug) { 'Release used AR connection for dispatcher thread.' }
        ActiveRecord::Base.connection_pool.release_connection
      end
    end

    def shutdown
    end

    def to_s
      self.class.name
    end

    class NullPool
      def initialize(*)
      end

      def post(*args)
        yield(*args)
      end
    end
  end
end
