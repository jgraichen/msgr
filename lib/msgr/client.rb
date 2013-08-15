require 'bunny'

module Msgr

  class Client
    include Celluloid
    include Logging

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
      @pool    = Pool.new Dispatcher, autostart: false
    end

    def running?
      @running
    end

    def routes
      @routes ||= Routes.new
    end

    def start
      @bunny.start
      @pool.start

      @running    = true
      @connection = Connection.new @bunny, routes, pool
    end

    def stop
      return unless running?

      @running = false
      log(:debug) { 'Stopping...' }

      @connection.release
      @pool.stop

      log(:debug) { 'Terminating...' }

      @connection.terminate
      @pool.terminate
      @bunny.stop

      log(:debug) { 'Terminated.' }
    end

    def publish(routing_key, payload)
      @connection.publish payload, routing_key: routing_key
    end
  end
end
