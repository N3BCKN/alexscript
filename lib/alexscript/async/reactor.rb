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
        @ready    = []    # [[fiber, resume_value], ...]
        @timers   = []    # sorted by deadline: [[deadline, block], ...]
        @io_read  = {}    # io => fiber
        @io_write = {}    # io => fiber
        @running  = false
      end

      # Fiber-local singleton. The root program starts with no reactor; the
      # first call to `uruchom` creates one and stores it in Fiber[:alex_reactor].
      # Child fibers inherit the reactor via Fiber's storage inheritance —
      # that's exactly the semantics we want: spawned async functions share
      # the reactor with their parent.
      def self.current
        Fiber[:alex_reactor] ||= new
      end

      def self.current?
        !Fiber[:alex_reactor].nil?
      end

      def self.reset_current!
        Fiber[:alex_reactor] = nil
      end

      # Public API for promises and built-ins 

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

      # Main loop

      # Drive the reactor until `promise` settles, then return its value
      # (or raise its rejection reason). Installs this reactor as the
      # Fiber::Scheduler for the duration — so TCPSocket#read, Net::HTTP
      # requests, Kernel.sleep etc. inside async fibers become non-blocking
      # automatically (Ruby stdlib dispatches through io_wait/kernel_sleep).
      #
      # Raises RuntimeError on deadlock (promise still pending but no
      # fibers ready, no timers pending, no I/O waiters).
      def run_until(promise)
        raise 'Reactor already running' if @running

        @running = true
        prev_scheduler = Fiber.scheduler
        Fiber.set_scheduler(self)

        begin
          loop do
            fire_ready_timers
            drain_ready_queue

            break unless promise.pending?

            if idle?
              raise 'Deadlock: promise will never settle (no ready fibers, no timers, no I/O)'
            end

            # If there are ready fibers, don't sleep — another iteration of
            # drain_ready_queue will pick them up. Only block on I/O/timers
            # when nothing is immediately runnable.
            next unless @ready.empty?

            do_io_select(next_timer_timeout)
          end
        ensure
          Fiber.set_scheduler(prev_scheduler)
          @running = false
        end

        if promise.fulfilled?
          promise.value
        else
          reason = promise.reason
          raise reason if reason.is_a?(Exception)
          raise Utils::AlexScriptError.new('BladWykonania', reason.to_s)
        end
      end

      # Internals

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
        @ready.empty? && @timers.empty? && @io_read.empty? && @io_write.empty?
      end

      # Block the reactor thread until either a timer fires or I/O becomes
      # ready. `timeout` is the max wait in seconds (nil for no timer).
      #
      # When nothing is waiting on I/O and we just have timers, this
      # behaves like Kernel.sleep(timeout) — the old behaviour. When
      # there are fibers waiting on readable/writable IOs, IO.select
      # multiplexes all of them and wakes whichever is ready first.
      def do_io_select(timeout)
        readable = @io_read.keys
        writable = @io_write.keys

        # Nothing to select on and no timer: shouldn't happen (idle? would
        # have raised deadlock). Guard defensively anyway.
        return if readable.empty? && writable.empty? && timeout.nil?

        # If we only have timers (no I/O), we could just sleep. But IO.select
        # with empty arrays and a timeout works fine and gives uniform code path.
        ready_read, ready_write, _ = IO.select(readable, writable, nil, timeout)

        (ready_read || []).each do |io|
          fiber = @io_read.delete(io)
          schedule_resume(fiber) if fiber
        end

        (ready_write || []).each do |io|
          fiber = @io_write.delete(io)
          schedule_resume(fiber) if fiber
        end
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

      # Seconds until the nearest timer fires, or nil if no timers pending.
      # Used as the timeout for IO.select — we want to wake up either when
      # I/O becomes ready or when the next timer is due, whichever first.
      def next_timer_timeout
        return nil if @timers.empty?
        diff = @timers.first[0] - monotonic_now
        [diff, 0].max
      end


      public

      # Fiber::SchedulerInterface
      #
      # Ruby stdlib (TCPSocket, Net::HTTP, Kernel.sleep etc.) calls these
      # when a scheduler is installed via Fiber.set_scheduler. By
      # implementing them, we get automatic non-blocking I/O for free —
      # our existing native libraries (SocketLibrary, HttpLibrary) don't
      # need any changes.
      #
      # Ref: https://docs.ruby-lang.org/en/3.4/Fiber/SchedulerInterface.html

      # Called when a fiber wants to wait for `io` to become readable or
      # writable. `events` is a bitmask of IO::READABLE / IO::WRITABLE.
      # `timeout` is the max wait in seconds, or nil for indefinite.
      #
      # We register the fiber as a waiter and yield; the main loop's
      # IO.select will resume us when the condition is met.
      def io_wait(io, events, timeout)
        fiber = Fiber.current

        wants_read  = (events & IO::READABLE) != 0
        wants_write = (events & IO::WRITABLE) != 0

        @io_read[io]  = fiber if wants_read
        @io_write[io] = fiber if wants_write

        # Timeout support: schedule a timer that wakes us with :timeout.
        # Simplified — we don't strictly need timeouts for basic TCP work,
        # but Net::HTTP sets them and will fail hard without this.
        if timeout
          schedule_timer(timeout * 1000) do
            if @io_read[io] == fiber
              @io_read.delete(io)
              schedule_resume(fiber, 0)  # 0 means "timed out, no events"
            end
            if @io_write[io] == fiber
              @io_write.delete(io)
              schedule_resume(fiber, 0)
            end
          end
        end

        Fiber.yield(:io_wait, io, events)

        # When we're resumed, the event bitmask of what actually happened
        # could be tracked. For MVP we return the requested events — the
        # caller just needs to know I/O is ready, specifics don't usually matter.
        events
      end

      # Called by Kernel.sleep(duration). A nil duration means "sleep forever"
      # (used e.g. by Mutex waits).
      def kernel_sleep(duration = nil)
        if duration
          sleep_fiber(duration * 1000)
        else
          # Park the fiber — it'll only wake if someone explicitly calls
          # unblock with its Fiber reference. For MVP this shouldn't
          # happen; we yield indefinitely.
          Fiber.yield(:park)
        end
      end

      # Called by low-level blocking primitives (Mutex#lock, Queue#pop).
      # `blocker` identifies what we're waiting on. `timeout` optional.
      #
      # MVP implementation: park the fiber. `unblock` will resume it.
      def block(blocker, timeout = nil)
        fiber = Fiber.current

        if timeout
          schedule_timer(timeout * 1000) do
            schedule_resume(fiber)
          end
        end

        Fiber.yield(:block, blocker)
        true
      end

      # Called to wake a fiber that was suspended via `block`. Note the
      # signature: `blocker` is the same object passed to block(), `fiber`
      # is the Ruby Fiber to resume.
      def unblock(_blocker, fiber)
        schedule_resume(fiber)
      end

      # Called by process/thread primitives we don't support yet.
      # Returning false signals stdlib to fall back to the default
      # (blocking) implementation.
      def process_wait(pid, flags)
        false
      end

      # Called when the scheduler is uninstalled. Clean up.
      def close
        # We've already cleared state in run_until's ensure; nothing extra
        # needed. This hook exists for schedulers that need to drain pending
        # work at program exit.
      end

      # Optional but recommended: the address_resolve hook. Without it,
      # DNS lookups (Socket.getaddrinfo) block the whole reactor. Ruby 3.1+.
      # Returning nil signals fallback to default behavior — which DOES block.
      # Acceptable for MVP; real async DNS is a post-MVP optimization.
      def address_resolve(hostname)
        nil
      end
    end
  end
end