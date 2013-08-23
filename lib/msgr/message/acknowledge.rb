module Msgr
  class Message

    #
    #
    module Acknowledge

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
        unless acked?
          @acked = true
          @connection.future(:ack, delivery_info.delivery_tag).value
        end
      end
    end
  end
end
