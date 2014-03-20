module Msgr

  # The Dispatcher receives incoming messages,
  # process them through a middleware stack and
  # delegate them to a new and fresh consumer instance.
  #
  class Dispatcher
    include Logging

    def call(message)
      dispatch message

      # Acknowledge message unless it is already acknowledged.
      message.ack unless message.acked?
    end

    def dispatch(message)
      consumer_class = Object.const_get message.route.consumer

      log(:debug) { "Dispatch message to #{consumer_class.name}" }

      consumer_class.new.dispatch message
    rescue => error
      log(:error) do
        "Dispatcher error: #{error.class.name}: #{error}\n" +
            error.backtrace.join("\n")
      end
    end

    def shutdown

    end

    def to_s
      self.class.name
    end
  end
end
