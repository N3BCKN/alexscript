# frozen_string_literal: true

require 'colorize'
require 'slop'

require_relative './core/core'
require_relative './utils/utils'

opts = Slop.parse do |o|
  o.bool '-f', '--full', 'run in full mode'
  o.bool '-t', '--time', 'measure time of execution'
end

# switch to REPL when no arguments
Repl.new if ARGV.empty?

filename = ARGV[0]

if filename&.end_with?('.ldz')
  begin
    source = File.read(filename)
    puts "File '#{filename}' has been read successfully."
  rescue Errno::ENOENT
    puts "Error: File '#{filename}' doesn't exist"
  rescue StandardError => e
    puts "Error: #{e.message}"
  end
else
  # puts "reading output directly from a console"
  source = ARGV[0]
end

start_time = Time.new if opts.time?

if opts.full?
  puts '***************************************'.colorize(:white)
  puts 'SOURCE:'.colorize(:white)
  puts '***************************************'.colorize(:white)
  puts source

  puts '***************************************'.colorize(:white)
  puts 'LEXER:'.colorize(:white)
  puts '***************************************'.colorize(:white)
end

lexer = Lexer.new(source)
tokens = lexer.tokenize!

if opts.full?
  lexer.tokens.each { |token| p token.print }

  puts '***************************************'.colorize(:white)
  puts 'PARSED AST:'.colorize(:white)
  puts '***************************************'.colorize(:white)
end

parser = Parser.new(tokens)
ast = parser.parse!

if opts.full?
  puts ast.pretty_print unless ast.nil?

  puts '***************************************'.colorize(:white)
  puts 'INTERPRETER:'.colorize(:white)
  puts '***************************************'.colorize(:white)
end

interpreter = Interpreter.new
puts interpreter.interpret_ast(ast)

if opts.time?
  end_time = Time.now
  puts "Execution time: #{end_time - start_time}s"
end
