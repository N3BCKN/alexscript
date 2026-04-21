# frozen_string_literal: true

module AlexScript
  module Async
    # ============================================================
    # ObietnicaImpl — Ruby-side implementation of AlexScript's Obietnica.
    #
    # Tracks three states: :pending, :fulfilled, :rejected. Once settled
    # (fulfilled or rejected), a promise cannot transition again — all
    # subsequent fulfill/reject calls are no-ops.
    #
    # Any fiber that calls #await on a pending promise yields control to
    # the reactor, and is registered as a "waiter". When the promise
    # settles, all its waiters are scheduled for resumption.
    #
    # The @handled flag tracks whether anyone has awaited (or will await)
    # this promise. Used in a future iteration to warn about unhandled
    # rejections, matching JS runtime behaviour. Not wired to stderr yet
    # — we only record the flag.
    #
    # This class is a pure Ruby object at this stage. It is NOT yet
    # exposed to AlexScript as a native class (that comes in Message 3
    # when we register it in NativeClassRegistry).
    # ============================================================
    class ObietnicaImpl
      STATE_PENDING   = :pending
      STATE_FULFILLED = :fulfilled
      STATE_REJECTED  = :rejected

      attr_reader :state, :value, :reason

      def initialize(reactor:)
        @state   = STATE_PENDING
        @value   = nil
        @reason  = nil
        @waiters = []
        @handled = false
        @reactor = reactor
      end

      # Settle the promise with a value. No-op if already settled.
      def fulfill(value)
        return if @state != STATE_PENDING

        @state = STATE_FULFILLED
        @value = value
        wake_waiters
      end

      # Settle the promise with a rejection reason. Reason is typically
      # an AlexScript::Utils::AlexScriptError, but any object is accepted.
      # No-op if already settled.
      def reject(reason)
        return if @state != STATE_PENDING

        @state  = STATE_REJECTED
        @reason = reason
        wake_waiters
      end

      # Block the current fiber until this promise settles, then return
      # the fulfilled value or raise the rejection reason.
      #
      # MUST be called from inside a fiber under the reactor; calling
      # from the main fiber (no reactor running) will raise a FiberError
      # because Fiber.yield has nowhere to return to.
      def await
        @handled = true

        case @state
        when STATE_FULFILLED
          return @value
        when STATE_REJECTED
          raise_reason
        when STATE_PENDING
          @waiters << Fiber.current
          Fiber.yield(:await, self)

          # Reactor has resumed us because the promise settled.
          case @state
          when STATE_FULFILLED then @value
          when STATE_REJECTED  then raise_reason
          else
            raise 'Invariant violation: fiber resumed from await but promise still pending'
          end
        end
      end

      # Register a callback to be invoked when this promise settles.
      # Fires synchronously if the promise is already settled, otherwise
      # queues the callback for invocation by wake_waiters.
      #
      # The callback receives the promise itself as argument, so it can
      # inspect #fulfilled? / #rejected? / #value / #reason to decide what
      # to do. This is a lower-level primitive than #await — it doesn't
      # require being called from a fiber, which makes it usable from
      # native lambdas (ObietnicaLibrary) that don't have fiber context.
      #
      # Used by combinators (wszystkie, dowolna, limit_czasu) and will
      # also underpin .potem() / .zlap() when chain methods are added.
      def on_settle(&block)
        @handled = true
        case @state
        when STATE_FULFILLED, STATE_REJECTED
          # Already settled — fire immediately, synchronously. This is
          # correct because on_settle callers don't expect async semantics;
          # they expect "call me when it's done, now if it's already done".
          block.call(self)
        when STATE_PENDING
          @settle_callbacks ||= []
          @settle_callbacks << block
        end
      end

      def pending?
        @state == STATE_PENDING
      end

      def fulfilled?
        @state == STATE_FULFILLED
      end

      def rejected?
        @state == STATE_REJECTED
      end

      def handled?
        @handled
      end

      private

      # Schedule every waiting fiber to be resumed by the reactor on its
      # next tick. We don't resume them synchronously here because
      # fulfill/reject may be called from deep inside a fiber body, and
      # immediate resume would blow the fiber stack under chains.
      def wake_waiters
        @waiters.each { |fiber| @reactor.schedule_resume(fiber) }
        @waiters.clear

        if @settle_callbacks
          @settle_callbacks.each { |cb| cb.call(self) }
          @settle_callbacks.clear
        end
      end

      def raise_reason
        raise @reason if @reason.is_a?(Exception)

        # Fallback: wrap non-exception reasons in BladWykonania so the
        # downstream handler has something uniform to catch.
        raise Utils::AlexScriptError.new('BladWykonania', @reason.to_s)
      end
    end
  end
end