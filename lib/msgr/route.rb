module Msgr

  class Route
    attr_reader :consumer, :action, :opts, :key
    alias_method :routing_key, :key

    def initialize(key, opts = {})
      @key  = key.to_s
      @opts = opts

      raise ArgumentError.new 'Routing key required.' unless @key.present?
      raise ArgumentError.new 'Missing `to` options.' unless @opts[:to]

      if (match = /\A(?<consumer>\w+)#(?<action>\w+)\z/.match(opts[:to].strip.to_s))
        @consumer = "#{match[:consumer].camelize}Consumer"
        @action   = match[:action].underscore
      else
        raise ArgumentError.new "Invalid consumer format: #{opts[:to].strip.to_s.inspect}. Must be `consumer_class#action`."
      end
    end

    def name
      "msgr.consumer-#{key}//#{consumer}##{action}"
    end
  end
end
