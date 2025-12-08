# frozen_string_literal: true

module AlexScript
  module Utils
    # model responsible for holding every single token detected by lexer
    class Token
      attr_reader :lexeme, :token_type, :line

      def initialize(token_type, lexeme, line)
        @token_type = token_type
        @lexeme = lexeme
        @line = line
      end

      def print
        "[#{@token_type}], #{@lexeme}, line: #{@line}"
      end
    end
  end
end
