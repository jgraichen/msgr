module Msgr

  class Pool
    include Celluloid
    include Logging
    attr_reader :size, :idle, :busy

    def initialize(runner_klass, opts = {})
      @runner_klass = runner_klass
      @runner_args  = opts[:args] ? Array(opts[:args]) : []
      @size         = (opts[:size] || Celluloid.cores).to_i
      @running      = false

      log(:debug) { "Inialize size => #{@size}" }

      start if opts[:autostart].nil? || opts[:autostart]
    end

    def running?
      @running
    end

    def start
      return if running?

      log(:debug) { 'Spin up worker pool' }
      @running = true

      @idle    = @size.times.map do |index|
        Worker.new_link Actor.current, index, @runner_klass, @runner_args
      end
      @busy    = []

      log(:debug) { 'Startup done. Invoke worker polling.' }

      @idle.each { |worker| async.poll worker }
    end

    # Request a graceful shutdown of all pool workers.
    #
    def stop
      log(:debug) { 'Graceful shutdown requested.' }

      @running = false
      @idle.each { |worker| worker.terminate }

      if busy.any?
        log(:debug) { "Wait for #{busy.size} workers to terminate." }

        wait :shutdown
      end

      log(:debug) { 'Graceful shutdown done.' }
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
      messages.push [message, args]
      after(0) { signal :dispatch }
    end

    # Called by worker to indicated it has finished processing.
    #
    # @param [Pool::Worker] worker Worker that finished processing.
    #
    def executed(worker)
      busy.delete worker

      if running?
        idle << worker
        poll worker
      else
        log(:debug) { "Terminate worker. Still #{busy.size} to go..." }

        worker.terminate if worker.alive?
        if busy.empty?
          log(:debug) { 'All worker down. Signal :shutdown.' }
          after(0) { signal :shutdown }
        end
      end
    end

    def poll(worker)
      return unless worker.alive?

      if running?
        if (message = exclusive { messages.shift })
          idle.delete worker
          busy << worker

          worker.dispatch message[0], message[1]
        else
          after(1) { poll worker }
        end
      else
        worker.terminate if worker.alive?
        after(0) { signal(:shutdown) } if @busy.empty?
      end
    end

    def to_s
      "#{self.class.name}[#{@runner_klass}]<#{object_id}>"
    end

    # Worker actor capsuling worker logic and dispatching
    # tasks to custom runner object.
    #
    class Worker
      include Celluloid
      include Logging
      attr_reader :pool, :index, :runner

      def initialize(pool, index, runner_klass, runner_args)
        @pool     = pool
        @poolname = pool.to_s
        @index    = index
        @runner   = runner_klass.new *runner_args

        log(:debug) { 'Worker ready.' }
      end

      # Dispatch given method and argument to custom runner.
      # Arguments are used to call `#send` on runner instance.
      #
      def dispatch(method, args)
        log(:debug) { "Dispatch to runner: #{runner.class.name}##{method.to_s}" }

        # Send method to custom runner.
        runner.send method, *args
      rescue => error
        log(:error) { "Received error from runner: #{error.message}\n#{error.backtrace.join("    \n")}" }
      ensure
        pool.executed Actor.current
      end

      def to_s
        "#{@poolname}[##{index}]"
      end
    end
  end
end
