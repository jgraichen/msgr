module Msgr

  class Client
    include Logging
    attr_reader :uri, :config

    def initialize(config = {})
      @uri          = ::URI.parse config[:uri] ? config.delete(:uri) : 'amqp://localhost/'
      config[:pass] ||= @uri.password

      @uri.user   = config[:user] ||= @uri.user || 'guest'
      @uri.scheme = (config[:ssl] ||= @uri.scheme.to_s.downcase == 'amqps') ? 'amqps' : 'amqp'
      @uri.host   = config[:host] ||= @uri.host || '127.0.0.1'
      @uri.port   = config[:port] ||= @uri.port
      @uri.path   = config[:vhost] ||= @uri.path.present? ? @uri.path : '/'
      config.reject! { |_, v| v.nil? }

      @config       = config
      @config[:max] ||= 2

      @mutex  = ::Mutex.new
      @routes = Routes.new
      @pid    ||= ::Process.pid

      log(:info) { "Created new client on process ##{@pid}..." }
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

    def connect
      mutex.synchronize do
        check_process!
        return if connection.running?

        log(:info) { "Connect to #{uri}..." }

        connection.connect
      end
    end

    def stop(opts = {})
      mutex.synchronize do
        check_process!

        log(:info) { "Stop on #{uri}..." }

        connection.release
        connection.delete if opts[:delete]
        connection.close
        dispatcher.shutdown

        reset
      end
    end

    def publish(payload, opts = {})
      mutex.synchronize do
        check_process!
        sync_publish payload, opts
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

    def sync_publish(payload, opts)
      begin
        payload = MultiJson.dump(payload)
        opts[:content_type] ||= 'application/json'
      rescue
        opts[:content_type] ||= 'application/text'
      end

      sync_publish_message payload.to_s, opts
    end

    def sync_publish_message(message, opts)
      connection.publish message, opts
    end

    def mutex
      @mutex
    end

    def check_process!
      unless ::Process.pid == @pid
        log(:warn) { "Fork detected. Reset internal state. (Old PID: #{@pid} / New PID: #{::Process.pid}" }

        reset
        @pid = ::Process.pid
      end
    end

    def connection
      @connection ||= Connection.new(uri, config, dispatcher).tap do
        log(:debug) { 'Created new connection..' }
      end
    end

    def dispatcher
      @dispatcher ||= Dispatcher.new(config).tap do
        log(:debug) { 'Created new dispatcher..' }
      end
    end

    def reset
      @connection = nil
      @pool       = nil
      @channel    = nil
      @bindings   = nil
      @dispatcher = nil
    end
  end
end
