module Msgr

  class Consumer
    include Logging

    attr_reader :message
    delegate :payload, to: :@message
    delegate :action, to: :'@message.route'
    delegate :consumer, to: :'@message.consumer'

    def dispatch(message)
      @message = message

      action = message.route.action.to_sym
      raise Msgr::NoAction.new "No action `#{action}` for `#{self.class.name}`." unless respond_to? action

      log(:debug) { "Invoke action #{action.inspect}." }

      send action

      log(:debug) { "Action #{action.inspect} done." }
    end

    def publish(data, opts = {})
      Msgr.client.publish(data, opts)
    end
  end
end
