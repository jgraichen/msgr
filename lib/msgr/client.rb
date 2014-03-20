require 'bunny'

module Msgr

  class Client
    include Logging
    attr_reader :uri, :config

    def initialize(config = {})
      @uri          = URI.parse config[:uri] ? config.delete(:uri) : 'amqp://localhost/'
      config[:pass] ||= @uri.password

      @uri.user   = config[:user] ||= @uri.user || 'guest'
      @uri.scheme = (config[:ssl] ||= @uri.scheme.to_s.downcase == 'amqps') ? 'amqps' : 'amqp'
      @uri.host   = config[:host] ||= @uri.host || '127.0.0.1'
      @uri.port   = config[:port] ||= @uri.port
      @uri.path   = config[:vhost] ||= @uri.path.present? ? @uri.path : '/'
      config.reject! { |_, v| v.nil? }

      @config = config
      @mutex  = Mutex.new
      @routes = Routes.new
    end

    def running?
      mutex.synchronize do
        check_process!
        connection.running?
      end
    end

    def start
      mutex.synchronize do
        check_process!
        return if connection.running?

        log(:info) { "Start on #{uri}..." }

        @routes << config[:routing_file] if config[:routing_file].present?
        @routes.reload
        connection.bind(@routes)
      end
    end

    def stop
      mutex.synchronize do
        check_process!

        log(:info) { "Stop on #{uri}..." }

        return unless connection.running?

        connection.release
        connection.close
        dispatcher.shutdown
      end
    end

    def publish(payload, opts = {})
      mutex.synchronize do
        check_process!
        connection.publish payload, opts
      end
    end

    def routes
      mutex.synchronize do
        @routes
      end
    end

    def release
      mutex.synchronize do
        check_process!
        return unless running?

        connection.release
      end
    end

    private
    def mutex
      @mutex
    end

    def check_process!
      unless Process.pid == @pid
        @connection    = nil
        @pool          = nil
        @channel       = nil
        @subscriptions = nil
        @pid           = ::Process.pid
      end
    end

    def connection
      @connection ||= Connection.new(uri, config, dispatcher)
    end

    def dispatcher
      @dispatcher ||= Dispatcher.new
    end
  end
end
