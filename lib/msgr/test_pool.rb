# frozen_string_literal: true

module Msgr
  class TestPool
    def initialize(*)
      @queue = []
      @mutex = Mutex.new
      @event = ConditionVariable.new
    end

    def post(message, &block)
      @mutex.synchronize do
        @queue << [block, message]
        @event.signal
      end
    end

    def run(**kwargs)
      @mutex.synchronize do
        ns_run(**kwargs)
      end
    end

    def clear
      @mutex.synchronize do
        @queue.clear
      end
    end

    alias reset clear

    private

    def ns_run(count: 1, timeout: 5)
      received = 0

      while received < count
        if (item = @queue.pop)
          item[0].call item[1]
          received += 1
        else
          start = Time.now.to_f

          @event.wait(@mutex, timeout)

          stop = Time.now.to_f
          diff = stop - start
          timeout -= diff

          if timeout <= 0
            raise Timeout::Error.new \
              "Expected to receive #{count} messages but received #{received}."
          end
        end
      end
    end

    class << self
      def new(*args)
        @instance ||= super(*args) # rubocop:disable Naming/MemoizedInstanceVariableName
      end

      def run(**kwargs)
        new.run(**kwargs)
      end

      def clear
        @instance ? @instance.clear : nil
      end

      alias reset clear
    end
  end
end
