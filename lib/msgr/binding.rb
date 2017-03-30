# frozen_string_literal: true
module Msgr
  class Binding
    include Logging

    attr_reader :queue, :subscription, :connection, :route, :dispatcher

    def initialize(connection, route, dispatcher)
      @connection = connection
      @route      = route
      @dispatcher = dispatcher
      @queue      = connection.queue(route.name)

      route.keys.each do |key|
        log(:debug) { "Bind #{key} to #{queue.name}." }

        queue.bind connection.exchange, routing_key: key
      end

      subscribe
    end

    def release
      subscription.cancel
    end

    def delete
      release
      queue.delete
    end

    def purge(release: true)
      self.release if release

      queue.purge

      subscribe if release
    end

    private

    def subscribe
      @subscription = queue.subscribe(manual_ack: true) do |*args|
        begin
          dispatcher.call Message.new(connection, *args, route)
        rescue => err
          log(:error) do
            "Rescued error from subscribe: #{err.class.name}: " \
            "#{err}\n#{err.backtrace.join("\n")}"
          end
        end
      end
    end
  end
end
