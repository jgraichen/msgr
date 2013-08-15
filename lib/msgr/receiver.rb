module Msgr

  # @api private
  #
  # Responsible for receiving messages from all defined
  # bindings and delegating them to worker pool. Implemented
  # as own class and celluloid actor instead of using bunny's
  # internal thread pool to allow easy and safe inter-thread
  # communication.
  #
  class Receiver
    include Celluloid
    attr_reader :connection, :logger, :channel, :exchange, :routes, :processing
    finalizer :shutdown

    def initialize(connection, logger, routes)
      @connection = connection
      @logger     = logger
      @routes     = routes

      logger.debug('Msgr::Receiver') { 'Start new receiver...' }

      @channel = connection.request_channel
      @channel.prefetch(10)

      @exchange = connection.request_exchange_on channel

      routes.each { |route| bindings << Binding.new(Actor.current, connection, route, logger) }
    end

    # Used to store al bindings. Allows use to
    # release bindings when receiver should not longer
    # receive messages but channel need to be open
    # to allow further acknowledgments.
    #
    def bindings
      @bindings ||= []
    end

    # Queue used to store messages to process.
    #
    def messages
      @messages ||= []
    end

    # Will be called by Binding when a message is received.
    #
    # @param [Message] message Received message.
    #
    def receive(message)
      messages << message
      signal :message_received
    end

    # Will be called by Pool when worker is ready to accept
    # new work. Will pop message for messages queue or wait
    # until a new one is received.
    #
    # @param [Pool::Worker] worker that has nothing to do.
    #
    def poll(worker)
      while (message = messages.pop).nil?
        wait :message_received
      end

      worker.dispatch message
    end

    # Release all bindings but do not close channel. Will not
    # longer receive any message but channel can be used to
    # acknowledgment currently processed messages.
    #
    def release
      return unless bindings.any?

      logger.debug('Msgr::Receiver') { 'Release all bindings.' }

      bindings.each { |binding| binding.cancel }
      bindings.clear
    end

    def shutdown
      release
      @channel.close unless @channel.open?
    end
  end
end
