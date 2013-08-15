module Msgr

  # The Dispatcher receives incoming messages,
  # process them through a middleware stack and
  # delegate them to a new and fresh consumer instance.
  #
  class Dispatcher
    include Logging

    def initialize

    end

    def call(message)
      log(:debug) { "Receive dispatched message: #{message.payload}" }

      sleep 10 * rand

      message.ack

      log(:debug) { 'Dispatched message acknowledged.' }
    end

    def to_s
      self.class.name
    end
  end
end
