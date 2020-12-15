# frozen_string_literal: true

require 'uri'
require 'cgi'
require 'json'

module Msgr
  # rubocop:disable Metrics/ClassLength
  class Client
    include Logging

    attr_reader :config

    def initialize(config = {})
      @config = {
        host: '127.0.0.1',
        vhost: '/',
        max: 2
      }

      @config.merge! parse(config.delete(:uri)) if config[:uri]
      @config.merge! config.symbolize_keys

      @mutex  = ::Mutex.new
      @routes = Routes.new
      @pid ||= ::Process.pid

      log(:debug) { "Created new client on process ##{@pid}..." }
    end

    # rubocop:enable all
    def uri
      @uri = begin
        uri = ::URI.parse('amqp://localhost')

        uri.user     = CGI.escape(config[:user]) if config.key?(:user)
        uri.password = '****'                    if config.key?(:pass)
        uri.host     = config[:host]             if config.key?(:host)
        uri.port     = config[:port]             if config.key?(:port)
        uri.scheme   = config[:ssl] ? 'amqps' : 'amqp'

        uri.path = "/#{CGI.escape(config[:vhost])}" if config.key?(:vhost) && config[:vhost] != '/'

        uri
      end
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

        log(:debug) { "Start on #{uri}..." }

        @routes << config[:routing_file] if config[:routing_file].present?
        @routes.reload
        connection.bind(@routes)
      end
    end

    def connect
      mutex.synchronize do
        check_process!
        return if connection.running?

        log(:debug) { "Connect to #{uri}..." }

        connection.connect
      end
    end

    def stop(opts = {})
      mutex.synchronize do
        check_process!

        log(:debug) { "Stop on #{uri}..." }

        connection.release
        connection.delete if opts[:delete]
        connection.close
        dispatcher.shutdown

        reset
      end
    end

    def purge(release: false)
      mutex.synchronize do
        check_process!

        log(:debug) { "Purge all queues on #{uri}..." }

        connection.purge(release: release)
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
      opts[:content_type] ||= 'application/json'
      sync_publish_message JSON.dump(payload).to_s, opts
    end

    def sync_publish_message(message, opts)
      connection.publish message, opts
    end

    attr_reader :mutex

    def check_process!
      return if ::Process.pid == @pid

      log(:warn) do
        "Fork detected. Reset internal state. (Old PID: #{@pid} / " \
        "New PID: #{::Process.pid}"
      end

      reset
      @pid = ::Process.pid
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

    def parse(uri)
      # Legacy parsing of URI configuration; does not follow usual
      # AMQP vhost encoding but used regular URL path
      uri = ::URI.parse(uri)

      config = {}
      config[:user] ||= uri.user if uri.user
      config[:pass] ||= uri.password if uri.password
      config[:host] ||= uri.host     if uri.host
      config[:port] ||= uri.port     if uri.port
      config[:vhost] ||= uri.path unless uri.path.empty?
      config[:ssl]   ||= uri.scheme.casecmp('amqps').zero?

      config
    end
  end
end
