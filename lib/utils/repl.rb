# frozen_string_literal: true

require 'readline'

class Repl
  def self.run
    version = '0.2.0' # replace this
    puts "LODZ jezyk, wersja: #{version}, 2024-#{Time.new.year}"
    puts "Wpisz 'koniec' aby zakonczyc"
    while input = Readline.readline('>>> ', true)
      exit 0 if input == 'koniec'

      lexer = Lexer.new(input)
      tokens = lexer.tokenize!
      parser = Parser.new(tokens)
      ast = parser.parse!

      interpreter = Interpreter.new
      puts interpreter.interpret!(ast).last
    end
  end
end
