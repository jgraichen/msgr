require 'bunny'

module Msgr

  class Client
    include Celluloid
    include Logging

    attr_reader :pool, :uri

    def initialize(config)
      @uri = URI.parse config[:uri] ? config.delete(:uri) : 'amqp://localhost/'
      config[:pass] ||= @uri.password

      @uri.user   = config[:user]  ||= @uri.user || 'guest'
      @uri.scheme = (config[:ssl]  ||= @uri.scheme.to_s.downcase == 'amqps') ? 'amqps' : 'amqp'
      @uri.host   = config[:host]  ||= @uri.host || '127.0.0.1'
      @uri.port   = config[:port]  ||= @uri.port
      @uri.path   = config[:vhost] ||= @uri.path.present? ? @uri.path : '/'
      config.reject! { |_,v| v.nil? }

      @config  = config
      @bunny   = Bunny.new config
      @pool    = Pool.new Dispatcher
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
