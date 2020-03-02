# frozen_string_literal: true

module Msgr
  class Binding
    include Logging

    attr_reader(
      :channel,
      :connection,
      :dispatcher,
      :queue,
      :route,
      :subscription
    )

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
        dispatcher.call Message.new(channel, *args, route)
      rescue StandardError => e
        log(:error) do
          "Rescued error from subscribe: #{e.class.name}: " \
          "#{e}\n#{e.backtrace.join("\n")}"
        end
      end
    end
  end
end
