# test_scheduler.rb
$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
require_relative '../lib/alexscript/core/core'
require_relative '../lib/alexscript/ast/ast'
require_relative '../lib/alexscript/utils/utils'
require_relative '../lib/alexscript/native/native'
require_relative '../lib/alexscript/async/async'

reactor = AlexScript::Async::Reactor.new
promise = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)

# Sprawdzenie 1: scheduler jest ustawiany podczas run_until.
fiber = Fiber.new do
  warn "[scheduler inside fiber] = #{Fiber.scheduler.class}"
  promise.fulfill(:ok)
end
reactor.schedule_resume(fiber)

warn "[scheduler before run_until] = #{Fiber.scheduler.inspect}"
reactor.run_until(promise)
warn "[scheduler after run_until] = #{Fiber.scheduler.inspect}"