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
    end
  end
end
