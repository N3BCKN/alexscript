# frozen_string_literal: true

require 'fiber'
require 'spec_helper'

require_relative '../lib/alexscript/core/core'
require_relative '../lib/alexscript/ast/ast'
require_relative '../lib/alexscript/utils/utils'
require_relative '../lib/alexscript/native/native'
require_relative '../lib/alexscript/async/async'

RSpec.describe AlexScript::Async::Reactor do
  let(:reactor) { described_class.new }

  describe '#run_until with a synchronously-fulfilled promise' do
    it 'returns the value without entering the main loop' do
      promise = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)
      promise.fulfill(42)

      expect(reactor.run_until(promise)).to eq(42)
    end

    it 'raises when the promise was rejected with an AlexScriptError' do
      promise = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)
      promise.reject(AlexScript::Utils::AlexScriptError.new('BladWykonania', 'boom'))

      expect {
        reactor.run_until(promise)
      }.to raise_error(AlexScript::Utils::AlexScriptError, /boom/)
    end
  end

  describe 'timers' do
    it 'fires a timer after the requested delay' do
      fired_at = nil
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      promise = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)
      reactor.schedule_timer(50) do
        fired_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        promise.fulfill(:done)
      end

      reactor.run_until(promise)

      elapsed_ms = (fired_at - started) * 1000
      # Generous upper bound for CI jitter; lower bound ensures we actually waited.
      expect(elapsed_ms).to be_between(40, 500)
    end

    it 'fires multiple timers in deadline order regardless of insertion order' do
      fired = []
      promise = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)

      reactor.schedule_timer(80) { fired << :c }
      reactor.schedule_timer(20) { fired << :a }
      reactor.schedule_timer(50) { fired << :b; promise.fulfill(:done) }
      # Note: final timer (:c at 80ms) may or may not fire before run_until
      # exits. We only assert ordering of those that DO fire before exit.

      reactor.run_until(promise)

      # :a and :b definitely fired; :c may or may not
      expect(fired.first(2)).to eq(%i[a b])
    end
  end

  describe 'fiber waking via ObietnicaImpl#await' do
    it 'resumes a waiting fiber when the promise fulfills' do
      promise      = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)
      trigger      = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)
      observed     = nil

      # Fiber A: awaits the trigger, then fulfills the outer promise.
      fiber_a = Fiber.new do
        value = trigger.await
        observed = value
        promise.fulfill(:done)
      end
      reactor.schedule_resume(fiber_a)

      # After A yields on `await trigger`, schedule a timer that fulfills it.
      reactor.schedule_timer(20) { trigger.fulfill('hello') }

      reactor.run_until(promise)

      expect(observed).to eq('hello')
    end

    it 'propagates rejection through await as a raised exception' do
      promise  = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)
      trigger  = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)
      caught   = nil

      fiber_a = Fiber.new do
        begin
          trigger.await
        rescue AlexScript::Utils::AlexScriptError => e
          caught = e
        end
        promise.fulfill(:done)
      end
      reactor.schedule_resume(fiber_a)

      reactor.schedule_timer(20) do
        trigger.reject(AlexScript::Utils::AlexScriptError.new('BladWykonania', 'trigger failed'))
      end

      reactor.run_until(promise)

      expect(caught).to be_a(AlexScript::Utils::AlexScriptError)
      expect(caught.message).to match(/trigger failed/)
    end

    it 'awakens two fibers both awaiting the same promise' do
      terminator = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)
      shared     = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)
      seen_a     = nil
      seen_b     = nil
      done_a     = false
      done_b     = false

      fiber_a = Fiber.new do
        seen_a = shared.await
        done_a = true
        terminator.fulfill(:ok) if done_a && done_b
      end
      fiber_b = Fiber.new do
        seen_b = shared.await
        done_b = true
        terminator.fulfill(:ok) if done_a && done_b
      end
      reactor.schedule_resume(fiber_a)
      reactor.schedule_resume(fiber_b)

      reactor.schedule_timer(20) { shared.fulfill(123) }

      reactor.run_until(terminator)

      expect(seen_a).to eq(123)
      expect(seen_b).to eq(123)
    end
  end

  describe 'deadlock detection' do
    it 'raises when a promise is pending with no pending work' do
      promise = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)
      # No fulfill, no timer, no ready fibers.

      expect {
        reactor.run_until(promise)
      }.to raise_error(/Deadlock/)
    end
  end

  describe 'fiber isolation' do
    it 'does not leak ContextTracker.current_line between fibers waking and yielding' do
      promise_a = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)
      promise_b = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)
      terminator = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)

      line_from_a_before = nil
      line_from_a_after  = nil

      fiber_a = Fiber.new do
        AlexScript::Utils::ContextTracker.current_line = 111
        line_from_a_before = AlexScript::Utils::ContextTracker.current_line
        promise_a.await
        # After resume, A's fiber-local context should still show 111,
        # regardless of what fiber B did in the meantime.
        line_from_a_after = AlexScript::Utils::ContextTracker.current_line
        terminator.fulfill(:ok)
      end

      fiber_b = Fiber.new do
        AlexScript::Utils::ContextTracker.current_line = 222
        promise_a.fulfill(:resume_a_now)
      end

      reactor.schedule_resume(fiber_a)
      reactor.schedule_timer(10) { reactor.schedule_resume(fiber_b) }

      reactor.run_until(terminator)

      expect(line_from_a_before).to eq(111)
      expect(line_from_a_after).to eq(111)
    end
  end
end