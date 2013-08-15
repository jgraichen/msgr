module Msgr
  class Publisher
    include Celluloid
    attr_reader :adapter, :logger

    def initialize(adapter, logger)
      @adapter = adapter
      @logger  = logger
    end

    def start
      channel
      exchange
    end

    def channel
      @channel ||= adapter.request_channel nil, 0
    end

    def exchange
      @exchange ||= adapter.request_exchange_on channel
    end

    def publish(payload, opts = {})
      exchange.publish payload, opts.merge(persistent: true)
    rescue Bunny::UnexpectedFrame => e
      logger.warn('Msgr::Adapter::Publisher#publish') { "Bunny connection error captured: #{e}" }

      @channel.close
      @channel = @exchange = nil
    end
  end
end
