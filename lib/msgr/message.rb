module Msgr

  class Message
    attr_reader :delivery_info, :metadata, :payload

    def initialize(connection, delivery_info, metadata, payload, route)
      @connection    = connection
      @delivery_info = delivery_info
      @metadata      = metadata
      @payload       = payload
      @route         = route
    end

    def ack
      @connection.ack delivery_info.delivery_tag
    end
  end
end
