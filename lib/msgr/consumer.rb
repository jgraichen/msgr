module Msgr

  class Consumer
    include Logging

    delegate :payload, to: :@message

    def dispatch(message)
      @message = message

      action = message.route.action.to_sym
      raise Msgr::NoAction.new "No action `#{action}` for `#{self.class.name}`." unless respond_to? action

      log(:debug) { "Invoke action #{action.inspect}." }

      send action

      log(:debug) { "Action #{action.inspect} done." }
    end
  end
end
