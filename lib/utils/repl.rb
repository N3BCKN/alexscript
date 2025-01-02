# frozen_string_literal: true

class Repl
  VERSION = '0.3.1'
  CURRENT_YEAR = Time.now.year

  def initialize
    @interpreter = Interpreter.new
    @env = Environment.new # new global env
    puts "Lodz Programming Language REPL 2024-#{CURRENT_YEAR} version #{VERSION}"
    puts "(wpisz 'wyjscie' aby zakończyć)"
    puts '-------------------------------------------------------'
    run
  end

  def run
    loop do
      input = read_multiline_input
      exit if input == 'wyjscie'

      begin
        lexer = Lexer.new(input)
        tokens = lexer.tokenize!

        parser = Parser.new(tokens)
        ast = parser.parse!

        result = @interpreter.interpret!(ast, @env)

        # Jeśli to wyrażenie print/println, po prostu czekamy na następną linię
        puts "=> #{result[1]}" if !(ast.is_a?(PrintStmt) || ast.is_a?(PrintlnStmt)) && (result && !result[1].nil?)

        # Prompt pojawi się tylko raz, przy kolejnym read_multiline_input
      rescue StandardError => e
        puts "Błąd: #{e.message}"
      end
    end
  end

  private

  def read_multiline_input
    input_lines = []
    brace_count = 0
    loop do
      print @prompt
      line = gets.chomp

      return 'wyjscie' if line.downcase == 'wyjscie'

      # Zliczamy nawiasy
      brace_count += line.count('{')
      brace_count -= line.count('}')

      input_lines << line

      # Jeśli wszystkie nawiasy są zamknięte i mamy jakiś input, kończymy
      break if brace_count == 0 && !input_lines.empty?

      # Zmieniamy prompt dla kolejnych linii
      @prompt = '>> '
    end

    # Przywracamy oryginalny prompt
    @prompt = '>> '

    input_lines.join("\n")
  end
end
