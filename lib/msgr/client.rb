require 'bunny'

module Msgr

  class Client
    include Celluloid
    attr_reader :pool

    def initialize(config)
      uri = URI.parse config[:uri] ? config.delete(:uri) : 'amqp://localhost/'
      uri.protocol = 'amqps'                   if config[:secure]
      uri.user     = config.delete :user       if config[:user]
      uri.password = config.delete :password   if config[:password]
      uri.host     = config.delete :host       if config[:host]
      uri.port     = config.delete(:port).to_i if config[:port]
      uri.path     = "/#{config.delete :vhost}".gsub /\/+/, '/' if config[:vhost]

      @config  = config
      @bunny   = Bunny.new uri.to_s
      @pool    = Pool.new Dispatcher, size: 5
      @running = true
    end

    def routes
      @routes ||= Routes.new
    end

    def start
      @bunny.start
      @connection = Connection.new @bunny, routes, pool
    end

    def stop
      return unless @running
      @running = false
      Msgr.logger.debug '[CLIENT] Stopping...'

      @connection.release
      @pool.stop

      Msgr.logger.debug '[CLIENT] Terminating...'

      @bunny.stop
      @connection.terminate
      @pool.terminate
      Msgr.logger.debug '[CLIENT] Stopped.'
    end
  end
end
