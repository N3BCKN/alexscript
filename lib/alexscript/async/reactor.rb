# frozen_string_literal: true

require 'fiber'

module AlexScript
  module Async
    # ============================================================
    # Reactor — cooperative scheduler for AlexScript fibers.
    #
    # This is the STAGE-1 reactor: it handles only the ready queue and
    # timers. No I/O waiters, no Fiber::Scheduler integration. That comes
    # in stage 2, after the language-level async/await is proven to work
    # end-to-end.
    #
    # Responsibilities at this stage:
    #   - Hold a queue of fibers ready to be resumed next tick.
    #   - Hold a sorted list of timers (deadline + block) and fire them
    #     when their time comes.
    #   - Run a main loop (#run_until) that drives everything until a
    #     specific terminating promise settles.
    #
    # The reactor is single-use per invocation of #run_until. It is not
    # meant to be long-lived across independent program runs, but it IS
    # meant to stay alive for the full lifetime of a long-running program
    # (e.g. an HTTP server) — a single call to uruchom(start_serwera)
    # keeps one reactor loop running until the server stops.
    # ============================================================
    class Reactor
      def initialize
        @ready   = []    # [[fiber, resume_value], ...]
        @timers  = []    # sorted by deadline: [[deadline, block], ...]
        @running = false
      end

      # --- Public API for promises and built-ins -----------------------

      # Add a fiber to the ready queue. It will be resumed on the next
      # tick of the main loop. Safe to call from inside a fiber body
      # (the fiber itself will continue executing; the scheduled resume
      # fires later).
      def schedule_resume(fiber, value = nil)
        @ready << [fiber, value]
      end

      # Register a block to run after `ms` milliseconds. The block runs
      # on the reactor thread, synchronously during tick. Typical use:
      # from inside a `uspij(ms)` built-in, schedule a block that
      # fulfills a promise with nil.
      def schedule_timer(ms, &block)
        deadline = monotonic_now + (ms / 1000.0)
        insert_sorted(@timers, [deadline, block])
      end

      # Suspend the current fiber for `ms` milliseconds. Called from
      # inside a fiber; yields to the reactor which will schedule the
      # fiber's resumption when the timer fires. The fiber's resume
      # value is `nil` on return.
      def sleep_fiber(ms)
        fiber = Fiber.current
        schedule_timer(ms) { schedule_resume(fiber) }
        Fiber.yield(:sleep, ms)
      end

      # --- Main loop ---------------------------------------------------

      # Drive the reactor until `promise` settles, then return its value
      # (or raise its rejection reason). This is the synchronous entry
      # point from AlexScript's `uruchom(...)` built-in.
      #
      # Raises RuntimeError on deadlock (promise still pending but no
      # fibers ready, no timers pending, no I/O waiters).
      def run_until(promise)
        raise 'Reactor already running' if @running

        @running = true
        begin
          loop do
            fire_ready_timers
            drain_ready_queue

            break unless promise.pending?

            if idle?
              raise 'Deadlock: promise will never settle (no ready fibers, no timers)'
            end

            # Only timers exist at this stage — sleep until the nearest one.
            sleep_until_next_timer
          end
        ensure
          @running = false
        end

        if promise.fulfilled?
          promise.value
        else
          # promise is rejected; ObietnicaImpl#await would have raised —
          # here we replicate that behaviour for the top-level caller.
          reason = promise.reason
          raise reason if reason.is_a?(Exception)

          raise Utils::AlexScriptError.new('BladWykonania', reason.to_s)
        end
      end

      # --- Internals ---------------------------------------------------

      private

      # Fire every timer whose deadline has passed. Each timer's block
      # typically schedule_resume's a fiber, so this method populates
      # @ready as a side effect.
      def fire_ready_timers
        now = monotonic_now
        while (entry = @timers.first) && entry[0] <= now
          _, block = @timers.shift
          block.call
        end
      end

      # Resume every fiber currently in the ready queue. A fiber may
      # yield back with a reason (:await, :sleep, etc.) — we handle the
      # hint but do not error on unknown reasons (future-proof).
      #
      # NOTE: we snapshot @ready and clear it before iterating, so that
      # fibers which schedule more fibers during their turn run in the
      # NEXT tick, not infinitely in this one. This prevents a tight
      # loop of `uruchom_rownolegle`-spawning fibers from starving timers.
      def drain_ready_queue
        batch = @ready
        @ready = []

        batch.each do |fiber, value|
          next unless fiber.alive?

          begin
            yielded = fiber.resume(value)
            # yielded: [:await, promise] | [:sleep, ms] | nil (fiber done)
            # At stage 1 we don't need to act on yielded values; promises
            # register their fibers via schedule_resume when they settle,
            # and sleep_fiber already scheduled a timer before yielding.
            _ = yielded
          rescue FiberError => e
            # Fiber resumed after completion or from wrong fiber — skip.
            warn "[Reactor] FiberError during resume: #{e.message}"
          rescue StandardError => e
            # Fiber bodies are wrapped in a bootstrap that catches their
            # exceptions and rejects the owning promise. If something
            # slips through to here, log and continue — one broken fiber
            # must never kill the reactor.
            warn "[Reactor] uncaught fiber exception: #{e.class}: #{e.message}"
          end
        end
      end

      def idle?
        @ready.empty? && @timers.empty?
      end

      # Block the reactor thread until the nearest timer deadline. At
      # stage 1 this is literally Kernel.sleep — no I/O to multiplex
      # against. Stage 2 replaces this with IO.select(readable, writable,
      # nil, timeout).
      def sleep_until_next_timer
        return if @timers.empty?

        wait = @timers.first[0] - monotonic_now
        Kernel.sleep(wait) if wait.positive?
      end

      # Use Process.clock_gettime(CLOCK_MONOTONIC) rather than Time.now.
      # Time.now can jump backwards on NTP sync; monotonic cannot. Matters
      # for long-running programs like servers.
      def monotonic_now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def insert_sorted(arr, entry)
        idx = arr.bsearch_index { |e| e[0] >= entry[0] } || arr.size
        arr.insert(idx, entry)
      end
    end
  end
end