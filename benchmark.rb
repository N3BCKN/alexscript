# frozen_string_literal: true

# Give the entry point a trivial program so AlexScript.start returns
# instead of dropping into the REPL on require.
ARGV.replace(['niech __bench = 0'])
require_relative 'lib/alexscript'

require 'benchmark'

def measure(source, runs: 5)
  AlexScript::Core::Lexer.new(source).tokenize!          # warmup / JIT
  (1..runs).map { Benchmark.realtime { AlexScript::Core::Lexer.new(source).tokenize! } }.min
end

puts "Ruby #{RUBY_VERSION}, YJIT #{defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled? ? 'on' : 'off'}"
puts format('%-8s %10s %10s %8s', 'linie', 'ascii', 'utf8', 'x')

[5_000, 10_000, 20_000, 40_000].each do |lines|
  ascii = "niech x = 1\n" * lines
  utf8  = "# zazolc gesla jazn: ó\n" + ascii   # jeden znak spoza ASCII, w komentarzu

  a = measure(ascii)
  u = measure(utf8)

  puts format('%-8d %9.4fs %9.4fs %7.1f', lines, a, u, u / a)
end

