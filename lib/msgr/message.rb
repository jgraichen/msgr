# frozen_string_literal: true
module Msgr
  class Message
    attr_reader :delivery_info, :metadata, :payload, :route

    def initialize(connection, delivery_info, metadata, payload, route)
      @connection    = connection
      @delivery_info = delivery_info
      @metadata      = metadata
      @payload       = payload
      @route         = route

      # rubocop:disable Style/GuardClause
      if content_type == 'application/json'
        @payload = MultiJson.load(payload)
        @payload.symbolize_keys! if @payload.respond_to? :symbolize_keys!
      end
    end

    def content_type
      @metadata.content_type
    end

    # Check if message is already acknowledged.
    #
    # @return [Boolean] True if message is acknowledged, false otherwise.
    # @api public
    #
    def acked?
      @acked ? true : false
    end

    # Send message acknowledge to broker unless message is
    # already acknowledged.
    #
    # @api public
    #
    def ack
      return if acked?

      @acked = true
      @connection.ack delivery_info.delivery_tag
    end

    # Send negative message acknowledge to broker unless
    # message is  already acknowledged.
    #
    # @api public
    #
    def nack
      return if acked?

      @acked = true
      @connection.nack delivery_info.delivery_tag
    end
  end
end
