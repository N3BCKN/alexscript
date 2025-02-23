# frozen_string_literal: true

require 'readline'

module AlexScript
  module Utils
    class Repl
      # VERSION = '0.4.11'
      CURRENT_YEAR = Time.now.year
      MAIN_PROMPT = '>> '
      CONT_PROMPT = '... '

      def initialize
        @interpreter = Core::Interpreter.new
        @env = Core::Environment.new # new global env
        @current_prompt = MAIN_PROMPT.dup
        puts "Lodz Programming Language REPL 2024-#{CURRENT_YEAR} version #{VERSION}"
        puts "(wpisz 'wyjscie()' aby zakończyć)"
        puts '-------------------------------------------------------'
        run
      end

      def run
        loop do
          input = read_multiline_input

          begin
            lexer = Core::Lexer.new(input)
            tokens = lexer.tokenize!

            parser = Core::Parser.new(tokens)
            ast = parser.parse!

            result = @interpreter.interpret!(ast, @env)

            # wait for the new line if it's 'pokaz/pokazl'
            if !(ast.is_a?(AST::PrintStmt) || ast.is_a?(AST::PrintlnStmt)) && (result && !result[1].nil?)
              puts "=> #{result[1]}"
            end
          rescue StandardError => e
            puts "Błąd: #{e.message}"
          end
        end
      end

      private

      def read_multiline_input
        input_lines = []
        brace_count = 0
        prompt = MAIN_PROMPT.dup

        loop do
          current_prompt = prompt || MAIN_PROMPT
          line = Readline.readline(current_prompt, true)

          return 'wyjscie' if line.nil? || line.downcase == 'wyjscie'

          Readline::HISTORY.pop if line.empty?

          brace_count += line.count('{')
          brace_count -= line.count('}')

          input_lines << line

          if brace_count == 0 && !input_lines.empty?
            prompt = MAIN_PROMPT.dup
            break
          else
            prompt = CONT_PROMPT.dup
          end
        rescue StandardError => e
          puts "Błąd wczytywania: #{e.message}"
          prompt = MAIN_PROMPT.dup
          break
        end

        # restore original prompt
        # @prompt = '>> '

        input_lines.join("\n")
      end
    end
  end
end
