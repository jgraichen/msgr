require 'bunny'

module Msgr

  class Client
    attr_reader :bunny, :config

    def initialize(config)
      uri = URI.parse config[:uri] ? config.delete(:uri) : 'amqp://localhost/'
      uri.protocol = 'amqps'                   if config[:secure]
      uri.user     = config.delete :user       if config[:user]
      uri.password = config.delete :password   if config[:password]
      uri.host     = config.delete :host       if config[:host]
      uri.port     = config.delete(:port).to_i if config[:port]
      uri.path     = "/#{config.delete :vhost}".gsub /\/+/, '/' if config[:vhost]

      @config = config
      @bunny = Bunny.new uri.to_s
    end

    def logger
      @logger ||= ::Logger.new $stdout
    end

    def channel
      @channel ||= bunny.create_channel
    end

    def exchange
      channel.topic 'msgr.test'
    end

    def routes
      @routes ||= Routes.new
    end

    def start
      logger.debug 'Start bunny client.'

      bunny.start

      logger.debug 'Register bindings on bunny channel.'

      routes.each do |route|
        bindings << Binding.new(self, route)
      end

    rescue ::Bunny::PossibleAuthenticationFailureError => error
      logger.debug "Catched bunny error: #{error}"
      raise ::Msgr::ConnectionError.new "Connection to broker '#{uri}' failed.", cause: error
    end

    def stop

    end
  end
end
