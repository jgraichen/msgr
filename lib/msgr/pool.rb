module Msgr

  class Pool
    include Celluloid
    include Logging
    attr_reader :size

    def initialize(runner_klass, opts = {})
      @runner_klass = runner_klass
      @runner_args  = opts[:args] ? Array(opts[:args]) : []
      @size         = (opts[:size] || Celluloid.cores).to_i
      @running      = false

      raise ArgumentError.new 'Pool size must be greater zero.' if @size <= 0

      log(:debug) { "Inialize size => #{@size}" }

      every([opts.fetch(:stats_interval, 30).to_i, 1].max) { log_status } if opts[:nostats].nil? || opts[:nostats]
    end

    def running?
      @running
    end

    def idle; @idle ||= [] end
    def busy; @busy ||= [] end

    def start
      return if running?

      log(:debug) { 'Spin up worker pool' }
      @running = true

      idle.clear
      busy.clear

      @size.times.map do |index|
        idle << Worker.new_link(Actor.current, index, @runner_klass, @runner_args)
      end

      log(:debug) { 'Pool ready.' }
    end

    def log_status
      log(:info) { "[STATUS] Idle: #{idle.size} Busy: #{busy.size}" }
    end

    # Request a graceful shutdown of all pool workers.
    #
    def stop
      log(:debug) { 'Graceful shutdown requested.' }

      @running = false
      idle.each { |worker| worker.terminate }
      idle.clear

      if busy.any?
        log(:debug) { "Wait for #{busy.size} workers to terminate." }

        wait :shutdown
      end

      log(:debug) { 'Graceful shutdown done.' }
    end
    alias_method :shutdown, :stop

    # Check if a worker is available.
    #
    # @return [Boolean] True if at least on idle worker is available, false otherwise.
    #
    def available?
      idle.any?
    end

    def messages
      @message ||= []
    end

    # Dispatch given message to a worker.
    #
    def dispatch(message, *args)
      log(:debug) { "Dispatch message to worker: #{message}" }

      fetch_idle_worker.future :dispatch, message, args
    end

    # Return an idle worker.
    #
    def fetch_idle_worker
      if (worker = idle.shift)
        worker
      else
        wait :worker_done
        fetch_idle_worker
      end
    end

    # Called by worker to indicated it has finished processing.
    #
    # @param [Pool::Worker] worker Worker that finished processing.
    #
    def executed(worker)
      busy.delete worker

      if running?
        idle << worker
        after(0) { signal :worker_done }
      else
        log(:debug) { "Terminate worker. Still #{busy.size} to go..." }

        worker.terminate if worker.alive?
        if busy.empty?
          log(:debug) { 'All worker down. Signal :shutdown.' }
          after(0) { signal :shutdown }
        end
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
        if pool.alive?
          pool.executed Actor.current
        else
          terminate
        end
      end

      def to_s
        "#{@poolname}[##{index}]"
      end
    end
  end
end
