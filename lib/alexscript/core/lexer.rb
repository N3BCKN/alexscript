# frozen_string_literal: true

module AlexScript
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
        @source_size = source.size # cache size for performance
        @tokens = []
        @line = 1
        @start = 0
        @current = 0
        
        # initialize keyword lookup table for O(1) lookup
        @keywords = {
          'niech' => :tok_let,
          'globalna' => :tok_global,
          'jesli' => :tok_if,
          'albo' => :tok_else,
          'albojesli' => :tok_elseif,
          'to' => :tok_then,
          'prawda' => :tok_true,
          'falsz' => :tok_false,
          'i' => :tok_and,
          'lub' => :tok_or,
          'dopoki' => :tok_while,
          'petla' => :tok_loop,
          'dla' => :tok_for,
          'w' => :tok_in,
          'funkcja' => :tok_func,
          'nic' => :tok_null,
          'zakoncz' => :tok_break,
          'nastepny' => :tok_continue,
          'pokaz' => :tok_print,
          'pokazl' => :tok_println,
          'zwroc' => :tok_return,
          'wyjscie' => :tok_exit,
          'wczytaj' => :tok_input,
          'import' => :tok_import,
          'proba' => :tok_try,
          'zlap' => :tok_catch,
          'wkoncu' => :tok_finally,
          'rzuc' => :tok_throw,
          'klasa' => :tok_class,
          'super' => :tok_super,
          'sam' => :tok_self,
          'statyczny' => :tok_static,
          'prywatne' => :tok_private,
          'abstrakcyjna' => :tok_abstract,
          'require_ruby' => :tok_require_ruby,
          'modul' => :tok_module,
          'dolacz' => :tok_include,
          'debug' => :tok_debug
        }.freeze
        
        # initialize ASCII character type lookup tables for fast character classification
        init_character_tables
        
        # initialize dispatch table for faster token handling
        init_dispatch_table
      end
      
      def tokenize!
        while @current < @source_size
          @start = @current
          
          # buffer next characters for faster access
          char = @current < @source_size ? @source[@current] : "\0"
          
          @current += 1  # inline advance for performance
          
          # use dispatch table for O(1) token handling
          if char.ord < 256
            method_name = @dispatch_table[char.ord]
            send(method_name, char)
          else
            handle_unknown(char)
          end
        end

        @tokens
      end

      private
      
      # initialize tables for fast character classification
      def init_character_tables
        @is_digit = Array.new(256, false)
        ('0'..'9').each { |c| @is_digit[c.ord] = true }
        
        @is_alpha = Array.new(256, false)
        ('a'..'z').each { |c| @is_alpha[c.ord] = true }
        ('A'..'Z').each { |c| @is_alpha[c.ord] = true }
        @is_alpha['_'.ord] = true
        
        @is_alnum = @is_digit.dup
        @is_alpha.each_with_index { |val, idx| @is_alnum[idx] ||= val }
        
        @is_whitespace = Array.new(256, false)
        [' '.ord, "\t".ord, "\r".ord].each { |c| @is_whitespace[c] = true }
      end
      
      # initialize dispatch table for O(1) character handling
      def init_dispatch_table
        @dispatch_table = Array.new(256, :handle_unknown)
        
        # setup handlers for various character types
        ('0'..'9').each { |c| @dispatch_table[c.ord] = :handle_numeral }
        ('a'..'z').each { |c| @dispatch_table[c.ord] = :handle_identifier }
        ('A'..'Z').each { |c| @dispatch_table[c.ord] = :handle_identifier }
        @dispatch_table['_'.ord] = :handle_identifier

        # OOP variables 
        @dispatch_table['@'.ord] = :handle_instance_var
        
        # whitespace and newlines
        @dispatch_table[' '.ord] = :handle_whitespace
        @dispatch_table["\t".ord] = :handle_whitespace
        @dispatch_table["\r".ord] = :handle_whitespace
        @dispatch_table["\n".ord] = :handle_newline
        
        # comments
        @dispatch_table['#'.ord] = :handle_single_line_comment
        
        # grouping tokens
        @dispatch_table['('.ord] = :handle_lparen
        @dispatch_table[')'.ord] = :handle_rparen
        @dispatch_table['{'.ord] = :handle_lcurly
        @dispatch_table['}'.ord] = :handle_rcurly
        @dispatch_table['['.ord] = :handle_lsquare
        @dispatch_table[']'.ord] = :handle_rsquare
        
        # punctuation
        @dispatch_table['.'.ord] = :handle_dot
        @dispatch_table[','.ord] = :handle_comma
        @dispatch_table[';'.ord] = :handle_semicolon
        @dispatch_table['?'.ord] = :handle_question
        @dispatch_table[':'.ord] = :handle_colon
        
        # operators
        @dispatch_table['+'.ord] = :handle_plus
        @dispatch_table['-'.ord] = :handle_minus
        @dispatch_table['*'.ord] = :handle_star
        @dispatch_table['/'.ord] = :handle_slash
        @dispatch_table['^'.ord] = :handle_caret
        @dispatch_table['%'.ord] = :handle_mod
        @dispatch_table['='.ord] = :handle_equal
        @dispatch_table['>'.ord] = :handle_greater
        @dispatch_table['<'.ord] = :handle_less
        @dispatch_table['!'.ord] = :handle_not
        
        # string literals
        @dispatch_table['"'.ord] = :handle_string
        @dispatch_table["'".ord] = :handle_string
      end
      
      # fast character type checking methods
      def is_digit?(char)
        char.ord < 256 && @is_digit[char.ord]
      end
      
      def is_alpha?(char)
        char.ord < 256 && @is_alpha[char.ord]
      end
      
      def is_alnum?(char)
        char.ord < 256 && @is_alnum[char.ord]
      end
      
      def is_whitespace?(char)
        char.ord < 256 && @is_whitespace[char.ord]
      end

      # advances current position by specified number of positions and returns current character
      # def advance(positions = 1)
      #   char = @source[@current]
      #   @current += positions
      #   char
      # end

      # creates and adds a new token to the tokens array
      def add_token(token_type)
        current_token = @source[@start...@current]
        @tokens << Utils::Token.new(token_type, current_token, @line)
      end

      # returns the next character without advancing position
      # returns null character if at end of source
      def peek
        return "\0" if @current >= @source_size
        @source[@current]
      end
      
      # returns character at position current + 1
      # returns null character if at end of source
      # def look_ahead
      #   return "\0" if @current >= @source_size
      #   @source[@current + 1]
      # end

      # checks if next character matches expected and advances position if it does
      def next_match(expected)
        return false if @current >= @source_size
        return false if @source[@current] != expected

        @current += 1
        true
      end
      
      # optimized handlers for different token types
      
      # whitespace handler - skips all consecutive whitespace at once
      def handle_whitespace(char)
        # skip the current whitespace character (already advanced)
        # and any following whitespace characters
        while @current < @source_size && is_whitespace?(@source[@current])
          @current += 1
        end
      end
      
      # newline handler - increments line counter and skips consecutive newlines
      def handle_newline(char)
        @line += 1
        
        # optimize for multiple consecutive newlines
        while @current < @source_size && @source[@current] == "\n"
          @line += 1
          @current += 1
        end
      end
      
      # single line comment handler - skips to end of line in one operation
      def handle_single_line_comment(char)
        # find the next newline or EOF
        newline_pos = @source.index("\n", @current)
        
        if newline_pos
          @current = newline_pos
        else
          # If no newline found, skip to end of file
          @current = @source_size
        end
      end
      
      # multi-line comment handler for slash-star comments
      def handle_multi_line_comment
        @current += 1  # Skip the '*' after '/'
        
        while @current < @source_size
          # optimized check for end of comment
          if @current + 1 < @source_size && 
             @source[@current] == '*' && @source[@current + 1] == '/'
            @current += 2  # Skip '*/'
            return
          end
          
          # count lines in comments
          if @source[@current] == "\n"
            @line += 1
          end
          
          @current += 1
        end
        
        Utils.lexing_error("Niezamknięty komentarz wieloliniowy", @line)
      end

      def handle_instance_var(char)
        #identifier after @ 
        if peek.match?(/[a-zA-Z_]/)
          @start = @current
          @current += 1 while peek.match?(/[a-zA-Z0-9_]/)
          var_name = @source[@start...@current]
          @tokens << Utils::Token.new(:tok_instance_var, var_name, @line)
        else
          Utils.lexing_error("Oczekiwano identyfikatora po @", @line)
        end
      end 
      
      # grouping and punctuation handlers
      def handle_lparen(char) 
        add_token(:tok_lparen)
      end
      
      def handle_rparen(char)
        add_token(:tok_rparen)
      end
      
      def handle_lcurly(char)
        add_token(:tok_lcurly)
      end
      
      def handle_rcurly(char)
        add_token(:tok_rcurly)
      end
      
      def handle_lsquare(char)
        add_token(:tok_lsquare)
      end
      
      def handle_rsquare(char)
        add_token(:tok_rsquare)
      end
      
      def handle_dot(char)
        add_token(:tok_dot)
      end
      
      def handle_comma(char)
        add_token(:tok_comma)
      end
      
      def handle_semicolon(char)
        add_token(:tok_semicolon)
      end
      
      def handle_question(char)
        add_token(:tok_question)
      end
      
      def handle_colon(char)
        if next_match(':')
          add_token(:tok_double_colon)  # ::
        else
          add_token(:tok_colon)  # :
        end
      end
      
      # operator handlers
      def handle_plus(char)
        if next_match('=')
          add_token(:tok_pluseq)
        else
          add_token(:tok_plus)
        end
      end
      
      def handle_minus(char)
        if next_match('=')
          add_token(:tok_minuseq)
        else
          add_token(:tok_minus)
        end
      end
      
      def handle_star(char)
        if next_match('=')
          add_token(:tok_stareq)
        else
          add_token(:tok_star)
        end
      end
      
      def handle_caret(char)
        add_token(:tok_caret)
      end
      
      def handle_mod(char)
        add_token(:tok_mod)
      end
      
      def handle_slash(char)
        if next_match('*')
          handle_multi_line_comment
        elsif next_match('=')
          add_token(:tok_slasheq)
        else
          add_token(:tok_slash)
        end
      end
      
      def handle_equal(char)
        if next_match('=')
          add_token(:tok_eq)
        else
          add_token(:tok_assign)
        end
      end
      
      def handle_greater(char)
        if next_match('=')
          add_token(:tok_greateroreq)
        else
          add_token(:tok_greater)
        end
      end
      
      def handle_less(char)
        if next_match('=')
          add_token(:tok_smalleroreq)
        elsif next_match('<')
          add_token(:tok_append)
        else
          add_token(:tok_smaller)
        end
      end
      
      def handle_not(char)
        if next_match('=')
          add_token(:tok_noteq)
        else
          add_token(:tok_not)
        end
      end
      
      # complex token handlers
      
      # optimized numeral handler for faster processing of numbers
      def handle_numeral(char)
        # current character is already a digit and has been consumed
        
        # fast-forward through all consecutive digits
        while @current < @source_size && is_digit?(@source[@current])
          @current += 1
        end
        
        # check for float
        if @current < @source_size && @source[@current] == '.' && 
           @current + 1 < @source_size && is_digit?(@source[@current + 1])
          @current += 1  # Skip the dot
          
          # fast-forward through all digits after the decimal point
          while @current < @source_size && is_digit?(@source[@current])
            @current += 1
          end
          
          add_token(:tok_float)
        else
          add_token(:tok_int)
        end
      end
      
      # optimized identifier handler using precomputed keyword lookup
      def handle_identifier(char)
        # first character is already consumed
        
        # fast-forward through all alphanumeric characters
        while @current < @source_size && is_alnum?(@source[@current])
          @current += 1
        end
        
        # Check if it's a keyword using our lookup table
        word = @source[@start...@current]
        token_type = @keywords[word] || :tok_identifier
        
        add_token(token_type)
      end
      
      # optimized string handler with direct buffer access
      def handle_string(char)
        str_quote = char
        @start += 1  # skip the opening quote
        
        # find closing quote
        end_pos = @current
        escape_mode = false
        
        while end_pos < @source_size
          c = @source[end_pos]
          
          if escape_mode
            escape_mode = false
          elsif c == '\\'
            escape_mode = true
          elsif c == str_quote
            break
          end
          
          end_pos += 1
        end
        
        if end_pos >= @source_size
          Utils.lexing_error("Niezakonczony ciag znakow.'", @line)
        end
        
        @current = end_pos + 1  # Position after closing quote
        text = @source[@start...end_pos].gsub(/\\(.)/) do |match|
          case $1
          when 'n'  then "\n"
          when 't'  then "\t"
          when 'r'  then "\r"
          when '\\' then "\\"
          when '"'  then '"'
          when '\'' then "'"
          when '0'  then "\0"
          else
            match  # unknown escape — preserve as-is
          end
        end
        
        @tokens << Utils::Token.new(:tok_string, text, @line)
      end
      
      # handler for unknown characters
      def handle_unknown(char)
        Utils.lexing_error("nieznany znak: #{char}", @line)
      end
    end
  end
end
