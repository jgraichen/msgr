# frozen_string_literal: true

module Msgr
  class Consumer
    include Logging

    attr_reader :message

    delegate :payload, to: :@message
    delegate :action, to: :'@message.route'
    delegate :consumer, to: :'@message.consumer'

    class << self
      def auto_ack?
        @auto_ack || @auto_ack.nil?
      end

      attr_writer :auto_ack
    end

    def dispatch(message)
      @message = message

      action = message.route.action.to_sym

      unless respond_to?(action)
        raise Msgr::NoAction.new \
          "No action `#{action}` for `#{self.class.name}`."
      end

      log(:debug) { "Invoke action #{action.inspect}." }

      send action

      log(:debug) { "Action #{action.inspect} done." }
    end

    def publish(data, opts = {})
      Msgr.client.publish(data, opts)
    end
  end
end
