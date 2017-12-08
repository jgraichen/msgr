# frozen_string_literal: true

module Msgr
  class Binding
    include Logging

    attr_reader :queue, :subscription, :connection, :channel, :route, :dispatcher

    def initialize(connection, route, dispatcher)
      @connection = connection
      @channel    = connection.channel(prefetch: route.prefetch)
      @route      = route
      @dispatcher = dispatcher
      @queue      = @channel.queue(route.name)

      route.keys.each do |key|
        log(:debug) { "Bind #{key} to #{queue.name}." }

        queue.bind @channel.exchange, routing_key: key
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
          dispatcher.call Message.new(channel, *args, route)
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
