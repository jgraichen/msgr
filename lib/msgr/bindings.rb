require 'active_support/core_ext/string/inflections'

module Msgr

  #
  class Bindings
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def configure(&block)
      instance_eval &block
    end

    def routes
      @routes ||= {}
    end

    def consumers
      @consumers ||= []
    end

    def reload!
      consumers.map { |consumer| consumer.unsubscribe }
      consumers.clear

      pool     = client.pool
      channel  = client.channel
      exchange = client.exchange
      #config  = client.config

      routes.each do |key, opts|
        consumer = opts[:consumer]
        action   = opts[:action]

        client.logger.debug "Register binding for #{key.inspect} to #{consumer}##{action}."

        queue    = channel.queue "msgr.consumer-#{key}//#{consumer}##{action}"
        consumers << queue.bind(exchange, routing_key: key).subscribe do |delivery_info, metadata, payload|
          client.logger.debug "Receive message #{payload.inspect}."
          pool.async.process [ delivery_info, metadata, payload ]
        end
      end
    end

    def route(key, opts = {})
      klass, consumer, action = extract_target! opts

      routes[key] = opts.merge(consumer: consumer, action: action)
    end

    private
    def extract_target!(opts)
      raise ArgumentError.new "Missing `to` options." unless opts[:to]

      if (match = /\A(?<consumer>\w+)#(?<action>\w+)\z/.match(opts[:to].strip.to_s))
        consumer = "#{match[:consumer].camelize}Consumer"
        action   = match[:action].underscore

        raise ArgumentError.new "Cannot find consumer class #{consumer.inspect}" unless defined? consumer

        [ Object.const_get(consumer), consumer, action ]
      else
        raise ArgumentError.new "Invalid `to` format: #{opts[:to].strip.to_s.inspect}. Must be 'consumer_class#action'."
      end
    end
  end
end
