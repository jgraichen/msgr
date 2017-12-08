# frozen_string_literal: true

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

      log(:debug) do
        "Initialize new dispatcher (#{config[:pool_class]}: #{config})..."
      end

      @config = config
      @pool = config[:pool_class].constantize.new config
    end

    def call(message)
      pool.post(message) do |msg|
        dispatch msg
      end
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    def dispatch(message)
      consumer_class = Object.const_get message.route.consumer

      log(:debug) { "Dispatch message to #{consumer_class.name}" }

      consumer_class.new.dispatch message

      # Acknowledge message unless it is already acknowledged or auto_ack is disabled.
      message.ack unless message.acked? or not consumer_class.auto_ack?
    rescue => error
      message.nack unless message.acked?

      log(:error) do
        "Dispatcher error: #{error.class.name}: #{error}\n" +
          error.backtrace.join("\n")
      end

      raise error if config[:raise_exceptions]
    ensure
      if defined?(ActiveRecord) &&
         ActiveRecord::Base.connection_pool.active_connection?
        log(:debug) { 'Release used AR connection for dispatcher thread.' }
        ActiveRecord::Base.connection_pool.release_connection
      end
    end

    def shutdown; end

    def to_s
      self.class.name
    end

    class NullPool
      def initialize(*); end

      def post(*args)
        yield(*args)
      end
    end
  end
end
