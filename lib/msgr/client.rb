require 'bunny'

module Msgr

  class Client
    include Celluloid
    include Logging

    attr_reader :pool, :uri

    def initialize(config)
      @uri = URI.parse config[:uri] ? config.delete(:uri) : 'amqp://localhost/'
      @uri.protocol = 'amqps'                   if config[:secure]
      @uri.user     = config.delete :user       if config[:user]
      @uri.password = config.delete :password   if config[:password]
      @uri.host     = config.delete :host       if config[:host]
      @uri.port     = config.delete(:port).to_i if config[:port]
      @uri.path     = "/#{config.delete :vhost}".gsub /\/+/, '/' if config[:vhost]

      @config  = config
      @bunny   = Bunny.new @uri.to_s
      @pool    = Pool.new Dispatcher, autostart: false

      @uri.password = nil
    end

    def running?; @running end
    def log_name; self.class.name end

    def routes
      @routes ||= Routes.new
    end

    def reload
      raise StandardError.new 'Client not running.' unless running?
      log(:info) { 'Reload client.' }

      @connection.release
      @connection.terminate

      log(:debug) { 'Create new connection.' }

      @connection = Connection.new @bunny, routes, pool

      log(:info) { 'Client reloaded.' }
    end

    def start
      log(:info) { "Start client to #{uri}" }

      @bunny.start
      @pool.start

      @running    = true
      @connection = Connection.new @bunny, routes, pool

      log(:info) { "Client started. pool: #{pool.size}" }
    end

    def stop
      return unless running?

      @running = false
      log(:info) { 'Graceful shutdown client...' }

      @connection.release
      @pool.stop

      log(:debug) { 'Terminating...' }

      @connection.terminate
      @pool.terminate
      @bunny.stop

      log(:info) { 'Terminated.' }
    end

    def publish(routing_key, payload)
      @connection.publish payload, routing_key: routing_key
    end
  end
end
