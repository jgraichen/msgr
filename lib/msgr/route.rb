# frozen_string_literal: true

module Msgr
  class Route
    attr_reader :consumer, :action, :opts

    MATCH_REGEXP = /\A(?<consumer>\w+)#(?<action>\w+)\z/.freeze

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def initialize(key, opts = {})
      @opts = opts
      raise ArgumentError.new 'Missing `to` options.' unless @opts[:to]

      add key

      result = MATCH_REGEXP.match(opts[:to].strip.to_s)

      unless result
        raise ArgumentError.new \
          "Invalid consumer format: #{opts[:to].strip.to_s.inspect}. " \
          'Must be `consumer_class#action`.'
      end

      @consumer = "#{result[:consumer].camelize}Consumer"
      @action   = result[:action].underscore
    end

    def keys
      @keys ||= []
    end
    alias routing_keys keys

    def prefetch
      @opts[:prefetch] || 1
    end

    def add(key)
      raise ArgumentError.new 'Routing key required.' unless key.present?

      keys << key
    end

    def accept?(_key, opts)
      self.opts == opts
    end

    def name
      "msgr.consumer.#{consumer}.#{action}"
    end
  end
end
