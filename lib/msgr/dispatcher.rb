module Msgr

  # The Dispatcher receives incoming messages,
  # process them through a middleware stack and
  # delegate them to a new and fresh consumer instance.
  #
  class Dispatcher

    def initialize

    end

    def call(message)
      Msgr.logger.debug "Receive dispatched message: #{message.payload}"

      sleep 2

      message.ack
      Msgr.logger.debug 'Dispatched message acknowledged.'
    end
  end
end
