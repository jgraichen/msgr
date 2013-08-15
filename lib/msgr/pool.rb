module Msgr

  class Pool
    include Celluloid
    attr_reader :size, :idle, :busy

    def initialize(runner_klass, opts = {})
      @runner_klass = runner_klass
      @runner_args  = opts[:args] ? Array(opts[:args]) : []
      @size         = (opts[:size] || Celluloid.cores).to_i
      @running      = false

      start
    end

    def running?
      @running
    end

    def start
      @idle    = @size.times.map do |index|
        Worker.new_link Actor.current, index, @runner_klass, @runner_args
      end
      @busy    = []
      @running = true

      @idle.each { |worker| async.poll worker }
    end

    # Request a graceful shutdown of all pool workers.
    #
    # @param [Hash] opts
    # @option opts [Boolean] :block If method should block until all worker are shutdown.
    #
    def stop(opts = {})
      opts = {block: true}.merge opts

      Msgr.logger.debug '[POOL] Graceful shutdown requested.'

      @running = false
      @idle.each { |worker| worker.terminate }

      if opts[:block] && busy.any?
        Msgr.logger.debug "[POOL] Wait for #{busy.size} workers to terminate."

        wait :shutdown

        Msgr.logger.debug '[POOL] Graceful shutdown done.'
      end
    end

    # Check if a worker is available.
    #
    # @return [Boolean] True if at least on idle worker is available, false otherwise.
    #
    def available?
      @idle.any?
    end

    def messages
      @message ||= []
    end

    # Dispatch given message to a worker.
    #
    def dispatch(message, *args)
      messages << [message, args]
      after(0) { signal :dispatch }
    end

    # Called by worker to indicated it has finished processing.
    #
    # @param [Pool::Worker] worker Worker that finished processing.
    #
    def executed(worker)
      Msgr.logger.debug "[POOL] Worker signals done."
      busy.delete worker

      if running?
        idle << worker
        poll worker
      else
        Msgr.logger.debug "[POOL] Worker terminated. Still #{busy.size} to go..."
        worker.terminate if worker.alive?
        if busy.empty?
          Msgr.logger.debug "[POOL] All worker down. Signal :shutdown."
          after(0) { signal :shutdown }
        end
      end
    end

    def poll(worker)
      return unless worker.alive?

      if running?
        if (message = messages.pop)
          idle.delete worker
          busy << worker

          worker.dispatch message[0], message[1]
        else
          after(1) { poll worker }
        end
      else
        worker.terminate if worker.alive?
        after(0) { puts "SHUTDOWN"; signal(:shutdown) } if @busy.empty?
      end
    end

    def to_s
      "#{self.class.name}<#{object_id}>[#{@runner_klass}]"
    end

    # Worker actor capsuling worker logic and dispatching
    # tasks to custom runner object.
    #
    class Worker
      include Celluloid
      attr_reader :pool, :index, :runner

      def initialize(pool, index, runner_klass, runner_args)
        @pool    = pool
        @pname   = pool.to_s
        @index   = index
        @runner  = runner_klass.new *runner_args
      end

      # Dispatch given method and argument to custom runner.
      # Arguments are used to call `#send` on runner instance.
      #
      def dispatch(method, args)
        # Send method to custom runner.
        runner.send method, *args
      rescue => error
        Msgr.logger.error "Received error from runner: #{error.message}\n#{error.backtrace.join("    \n")}"
      ensure
        pool.executed Actor.current
      end

      def to_s
        "#{@pname}[#{index}] (#{Thread.current.object_id})"
      end
    end
  end
end
