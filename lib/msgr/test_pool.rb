module Msgr
  class TestPool
    def initialize(*)
      @mutex = Mutex.new
      @queue = []
    end

    def post(*args, &block)
      @mutex.synchronize { @queue << [block, args] }
    end

    def run(timeout: 5, count: 1)
      Timeout.timeout(timeout) do
        while count > 0
          @mutex.synchronize do
            if (item = @queue.pop)
              item[0].call(*item[1])

              count -= 1
            end
          end
        end
      end
    end

    def reset
      @queue.clear
    end

    class << self
      def new(*args)
        @instance ||= super(*args)
      end

      def run(*args)
        new.run(*args)
      end

      def reset
        @instance ? @instance.reset : nil
      end
    end
  end
end
