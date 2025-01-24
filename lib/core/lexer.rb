# frozen_string_literal: true

module Core
  # Lexer class responsible for tokenizing source code
  # Handles various token types including:
  # - Single character tokens (parentheses, operators)
  # - Multi-character tokens (numbers, strings)
  # - Keywords (in Polish)
  # - Comments (single-line and multi-line)
  class Lexer
    attr_reader :tokens

    def initialize(source)
      @source = source
      @source_size = source.size # Cache size for performance
      @tokens = []
      @line = 1
      @start = 0
      @current = 0
    end

    def tokenize!
      while @current < @source_size
        @start = @current
        char = advance

        # Whitespace handling and line counting
        if char == "\n"
          @line += 1
        elsif ["\t", "\r", ' '].include?(char)
          next
        # Single-line comments - skip until newline
        elsif char == '#'
          while peek != "\n" && @current <= @source.size
            @line += 1 if peek == "\n"
            advance
          end

        # Single character tokens - grouping
        elsif char == '('
          add_token(:tok_lparen)
        elsif char == ')'
          add_token(:tok_rparen)
        elsif char == '{'
          add_token(:tok_lcurly)
        elsif char == '}'
          add_token(:tok_rcurly)
        elsif char == '['
          add_token(:tok_lsquare)
        elsif char == ']'
          add_token(:tok_rsquare)

        # Single character tokens - punctuation
        elsif char == '.'
          add_token(:tok_dot)
        elsif char == ','
          add_token(:tok_comma)
        elsif char == ';'
          add_token(:tok_semicolon)
        elsif char == '?'
          add_token(:tok_question)

        # Single character tokens - operators
        elsif char == '+'
          if next_match('=')
            add_token(:tok_pluseq)
          else
            add_token(:tok_plus)
          end

        elsif char == '-'
          if next_match('=')
            add_token(:tok_minuseq)
          else
            add_token(:tok_minus)
          end

        elsif char == '*'
          if next_match('=')
            add_token(:tok_stareq)
          else
            add_token(:tok_star)
          end
        elsif char == '^'
          add_token(:tok_caret)
        elsif char == '%'
          add_token(:tok_mod)

        # Multi-line comments
        elsif char == '/'
          if next_match('*') #
            advance
            loop do
              break if @current >= @source_size # end of the file

              # check for closing sequence '*/'
              if peek == '*' && look_ahead == '/'
                advance(2) # skip closing comment statement
                break
              end

              @line += 1 if peek == "\n" # count commented line
              advance
            end
          elsif next_match('=') # compound assignment /=
            add_token(:tok_slasheq)
          else # regular division token
            add_token(:tok_slash)
          end

        # Two-character operators
        elsif char == '='
          if next_match('=')
            add_token(:tok_eq)
          else
            add_token(:tok_assign)
          end
        # elsif char == '~'
        #   add_token(:tok_noteq) if next_match('=')
        elsif char == '>'
          if next_match('=')
            add_token(:tok_greateroreq)
          else
            add_token(:tok_greater)
          end
        elsif char == '<'
          if next_match('=')
            add_token(:tok_smalleroreq)
          elsif next_match('<')
            add_token(:tok_append)
          else
            add_token(:tok_smaller)
          end
        elsif char == '!'
          if next_match('=')
            add_token(:tok_noteq)
          else
            add_token(:tok_not) # logical not
          end
        elsif char == ':'
          add_token(:tok_colon)
        # Complex tokens
        elsif char.between?('0', '9')
          handle_numeral
        elsif ["\'", '"'].include?(char)
          handle_string(char)
        elsif char.match?(/[a-zA-Z]/) || char == '_'
          handle_identifier
        else
          Utils.lexing_error("unknown character: #{char}", @line)
        end
      end

      @tokens
    end

    private

    # Advances current position by specified number of positions and returns current character
    def advance(positions = 1)
      char = @source[@current]
      @current += positions
      char
    end

    # Creates and adds a new token to the tokens array
    def add_token(token_type)
      current_token = @source[@start...@current]
      @tokens << Utils::Token.new(token_type, current_token, @line)
    end

    # Returns the next character without advancing position
    # Returns null character if at end of source
    def peek
      return "\0" if @current >= @source_size

      @source[@current]
    end

    # Handles numeric literals, both integer and float
    def handle_numeral
      advance while peek && peek.between?('0', '9')

      if peek == '.' && look_ahead&.between?('0', '9')
        advance
        advance while peek && peek.between?('0', '9')
        add_token(:tok_float)
      else
        add_token(:tok_int)
      end
    end

    # Handles identifiers and keywords
    def handle_identifier
      advance while peek.match?(/[a-zA-Z0-9_]/)

      word = @source[@start...@current]

      # restriced words
      token_type = case word
                   when 'niech' then :tok_let
                   when 'globalna' then :tok_global
                   when 'jesli' then :tok_if
                   when 'albo' then :tok_else
                   when 'albojesli' then :tok_elseif
                   when 'to' then :tok_then
                   when 'prawda' then :tok_true
                   when 'falsz' then :tok_false
                   when 'i' then :tok_and
                   when 'lub' then :tok_or
                   when 'dopoki' then :tok_while
                   when 'petla' then :tok_loop
                   when 'dla' then :tok_for
                   when 'w' then :tok_in
                   when 'funkcja' then :tok_func
                   when 'nic' then :tok_null
                   when 'zakoncz' then :tok_break
                   when 'nastepny' then :tok_continue
                   when 'pokaz' then :tok_print
                   when 'pokazl' then :tok_println
                   when 'zwroc' then :tok_return
                   when 'wyjscie' then :tok_exit
                   when 'wczytaj' then :tok_input
                   else :tok_identifier
                   end

      add_token(token_type)
    end

    # Handles string literals (both single and double quoted)
    def handle_string(char)
      str_quote = char
      @start += 1 # Skip the opening quote
      advance while peek != str_quote && @current <= @source_size

      Utils.lexing_error("Unterminated string.'", @line) if @current >= @source_size

      final_pos = @current
      advance
      text = @source[@start...final_pos]
      @tokens << Utils::Token.new(:tok_string, text, @line)
    end

    # Returns character at position current + 1
    # Returns null character if at end of source
    def look_ahead
      return "\0" if @current >= @source_size

      @source[@current + 1]
    end

    # Checks if next character matches expected and advances position if it does
    def next_match(expected)
      return false if @current >= @source_size
      return false if @source[@current] != expected

      @current += 1
      true
    end
  end
end
