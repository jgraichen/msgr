module Msgr

  class Route
    attr_reader :consumer, :action, :opts

    def initialize(key, opts = {})
      @opts = opts
      raise ArgumentError.new 'Missing `to` options.' unless @opts[:to]

      add key

      if (match = /\A(?<consumer>\w+)#(?<action>\w+)\z/.match(opts[:to].strip.to_s))
        @consumer = "#{match[:consumer].camelize}Consumer"
        @action   = match[:action].underscore
      else
        raise ArgumentError.new "Invalid consumer format: #{opts[:to].strip.to_s.inspect}. Must be `consumer_class#action`."
      end
    end

    def keys
      @keys ||= []
    end
    alias_method :routing_keys, :keys

    def add(key)
      raise ArgumentError.new 'Routing key required.' unless key.present?

      keys << key
    end

    def accept?(key, opts)
      self.opts == opts
    end

    def name
      "msgr.consumer.#{consumer}.#{action}"
    end
  end
end
