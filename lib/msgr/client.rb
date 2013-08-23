require 'bunny'

module Msgr

  class Client
    include Celluloid
    include Logging

    attr_reader :uri

    def initialize(config = {})
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
      @pool    = Pool.new Dispatcher, size: config[:size]
    end

    def running?; @running end
    def log_name; self.class.name end

    def routes
      @routes ||= Routes.new
    end

    def new_connection
      @connection = Connection.new @bunny, routes, @pool, prefix: @config[:prefix]
    end

    def reload
      raise StandardError.new 'Client not running.' unless running?
      log(:info) { 'Reload client.' }

      @connection.release
      @connection.terminate

      log(:debug) { 'Create new connection.' }
      new_connection

      log(:info) { 'Client reloaded.' }
    end

    def start
      log(:info) { "Start client to #{uri}" }

      @bunny.start
      @pool.start
      @running = true
      new_connection

      log(:info) { 'Client started.' }
    end

    def stop(opts = {})
      return unless running?
      opts.reverse_merge! timeout: 10, delete: false

      stop_connection opts

      @running = false
      wait_for_graceful_shutdown opts if opts[:timeout]

      log(:debug) { 'Terminating...' }

      if opts[:delete]
        log(:debug) { 'Delete connection.' }
        @connection.delete
      end
      @connection.terminate
      @bunny.stop

      log(:info) { 'Terminated.' }
    end

    def publish(routing_key, payload)
      @connection.publish payload, routing_key: routing_key
    end

    private
    def stop_connection(opts)
      timeout = [opts[:wait_empty].to_i, 1].max

      begin
        if opts[:wait_empty]
          log(:info) { "Shutdown requested: Wait until all queues are empty. (TIMEOUT: #{timeout}s)" }
          @connection.future(:release, true).value timeout
        else
          @connection.future(:release).value timeout
        end
      rescue TimeoutError
        log(:warn) { "Could release connection within #{timeout} seconds." }
      end
    end

    def wait_for_graceful_shutdown(opts)
      timeout = [opts[:timeout].to_i, 0].max
      log(:info) { "Attempting graceful shutdown within #{timeout} seconds..." }

      @pool.future(:stop).value timeout
    rescue TimeoutError
      log(:warn) { "Could not shutdown pool within #{timeout} seconds." }
    end
  end
end
