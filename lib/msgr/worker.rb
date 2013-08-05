module Msgr

  class Worker
    include ::Celluloid

    attr_reader :client

    def initialize(client)
      @client = client
    end

    def process(message)
      client.logger.info message[2]
    end
  end
end
