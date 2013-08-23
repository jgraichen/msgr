module Msgr

  require 'msgr/message/acknowledge'

  class Message
    include Acknowledge
    attr_reader :delivery_info, :metadata, :payload, :route

    def initialize(connection, delivery_info, metadata, payload, route)
      @connection    = connection
      @delivery_info = delivery_info
      @metadata      = metadata
      @payload       = payload
      @route         = route

      if content_type == 'application/json'
        @payload = JSON[payload].symbolize_keys
      end
    end

    def content_type
      @metadata.content_type
    end
  end
end
