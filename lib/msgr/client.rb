module Msgr

  class Client
    include Celluloid
    attr_reader :opts, :uri, :bunny
    finalizer :stop

    def initialize(config)
      uri = URI.parse config[:uri] ? config.delete(:uri) : 'amqp://localhost/'
      uri.protocol = 'amqps'                   if config[:secure]
      uri.user     = config.delete :user       if config[:user]
      uri.password = config.delete :password   if config[:password]
      uri.host     = config.delete :host       if config[:host]
      uri.port     = config.delete(:port).to_i if config[:port]
      uri.path     = "/#{config.delete :vhost}".gsub /\/+/, '/' if config[:vhost]

      @uri   = uri.to_s
      @config = config
      @bunny = Bunny.new uri.to_s
    end

    def logger
      @logger ||= ::Logger.new $stdout
    end

    def pool
      @pool ||= Worker.pool args: Actor.current
    end

    def bindings
      @bindings ||= Bindings.new self
    end

    def channel
      @channel ||= bunny.create_channel
    end

    def exchange
      @channel.topic 'msgr.test'
    end

    def start(opts = {})
      @started = true

      logger.debug "Start bunny client."

      bunny.start

      logger.debug "Register bindings on bunny channel."

      bindings.reload!

      if opts[:block]
        logger.debug "Msgr running. Blocking call."
        loop do
          Fiber.yield
        end
      end
    rescue ::Bunny::PossibleAuthenticationFailureError => error
      logger.debug "Catched bunny error: #{error}"
      raise ::Msgr::ConnectionError.new "Connection to broker '#{uri}' failed.", cause: error
    end

    def stop
      return unless @started
      @channel.close if @channel
      @bunny.close   if @bunny
    end

    def publish(payload, opts = {})
      #logger.debug "Publish message #{payload.inspect} to #{opts[:routing_key].inspect}."
      exchange.publish payload, opts
    end
  end
end
