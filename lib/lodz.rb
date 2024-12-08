# frozen_string_literal: true
require('colorize')

require_relative './core/core'
require_relative './utils/utils'

if ARGV.size == 0
  raise "Wrong number of arguments given"
end

filename = ARGV[0]

if filename&.end_with?('.ldz')
  begin
    source = File.read(filename)
    puts "File '#{filename}' has been read successfully."
    # Dalsza obróbka pliku
  rescue Errno::ENOENT
    puts "Error: File '#{filename}' doesn't exist"
  rescue => e
    puts "Error: #{e.message}"
  end
else
  puts "reading output directly from a console"
  source = ARGV.join(' ')
end

puts "***************************************".colorize(:white)
puts "SOURCE:".colorize(:white)
puts "***************************************".colorize(:white)
puts source

puts "***************************************".colorize(:white)
puts "LEXER:".colorize(:white)
puts "***************************************".colorize(:white)
lexer = Lexer.new(source)
tokens = lexer.tokenize!

lexer.tokens.each{|token| p token.print}


puts "***************************************".colorize(:white)
puts "PARSED AST:".colorize(:white)
puts "***************************************".colorize(:white)
parser = Parser.new(tokens)
ast = parser.parse!
puts ast.pretty_print

puts "***************************************".colorize(:white)
puts "INTERPRETER:".colorize(:white)
puts "***************************************".colorize(:white)

interpreter = Interpreter.new
puts interpreter.interpret!(ast)