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

      # Byte constants. The lexer compares bytes, not characters, so that
      # source containing non-ASCII text (Polish strings, comments, and — from
      # phase 2 — identifiers) does not degrade String#[] to a linear scan.
      B_NEWLINE   = 10
      B_QUOTE_D   = 34   # "
      B_HASH      = 35   # #
      B_QUOTE_S   = 39   # '
      B_STAR      = 42   # *
      B_ZERO      = 48
      B_SEVEN     = 55
      B_SLASH     = 47   # /
      B_DOT       = 46
      B_BACKSLASH = 92
      B_LCURLY    = 123
      B_RCURLY    = 125

      # UTF-8 lead bytes of the 18 Polish letters. All are two-byte sequences
      # with lead byte C3, C4 or C5, so a 3x256 table resolves them in O(1)
      # without decoding anything.
      POLISH_LEAD_MIN = 0xC3
      POLISH_LEAD_MAX = 0xC5

      POLISH_TRAIL_BYTES = {
        0xC3 => [0xB3, 0x93].freeze,                                 # ó Ó
        0xC4 => [0x85, 0x84, 0x87, 0x86, 0x99, 0x98].freeze,         # ą Ą ć Ć ę Ę
        0xC5 => [0x82, 0x81, 0x84, 0x83, 0x9B, 0x9A,                 # ł Ł ń Ń ś Ś
                 0xBA, 0xB9, 0xBC, 0xBB].freeze                      # ź Ź ż Ż
      }.freeze

      def initialize(source)
        @source = source
        @source_size = source.bytesize  # cache size for performance
        @tokens = []
        @line = 1
        @start = 0
        @current = 0
        
        # keyword lookup table — single source of truth, shared across all Lexer instances
        @keywords = Utils::KEYWORDS
        
        # initialize ASCII character type lookup tables for fast character classification
        init_character_tables
            
        # initialize dispatch table for faster token handling
        init_character_tables
        init_polish_tables
        init_dispatch_table
      end
      
      def tokenize!
        while @current < @source_size
          @start = @current
          byte = @source.getbyte(@current)  # Integer 0..255, O(1), no allocation
          @current += 1
          send(@dispatch_table[byte], byte)
        end

        @tokens
      end

      private

      def is_hex_digit?(byte)
        @is_digit[byte] ||
          (byte >= 97 && byte <= 102) ||   # a-f
          (byte >= 65 && byte <= 70)       # A-F
      end
      
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

      def init_polish_tables
        @is_polish_trail = Array.new(3) { Array.new(256, false) }
        POLISH_TRAIL_BYTES.each do |lead, trails|
          row = @is_polish_trail[lead - POLISH_LEAD_MIN]
          trails.each { |t| row[t] = true }
        end
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
        @dispatch_table['~'.ord] = :handle_tilde
        @dispatch_table['&'.ord] = :handle_ampersand
        @dispatch_table['|'.ord] = :handle_pipe
        
        # string literals
        @dispatch_table['"'.ord] = :handle_string
        @dispatch_table["'".ord] = :handle_string


        # Polish letters open an identifier just like an ASCII letter does
        (POLISH_LEAD_MIN..POLISH_LEAD_MAX).each { |b| @dispatch_table[b] = :handle_polish_identifier }
      end
      
      # fast character type checking methods
      def is_digit?(byte)  = @is_digit[byte]
      def is_alnum?(byte)  = @is_alnum[byte]
      def is_whitespace?(byte) = @is_whitespace[byte]
      def is_alpha?(byte) = @is_alpha[byte]

      # creates and adds a new token to the tokens array
      def add_token(token_type)
        lexeme = @source.byteslice(@start, @current - @start).force_encoding(Encoding::UTF_8)
        @tokens << Utils::Token.new(token_type, lexeme, @line)
      end


      # Returns the next byte, or -1 at end of source. -1 never matches any
      # table entry or comparison, which replaces the old "\0" sentinel.
      def peek_byte
        return -1 if @current >= @source_size
        @source.getbyte(@current)
      end
      
      # `expected` stays a one-character String literal so call sites remain
      # readable: next_match('=') rather than next_match(61).
      def next_match(expected)
        return false if @current >= @source_size
        return false if @source.getbyte(@current) != expected.getbyte(0)

        @current += 1
        true
      end
      
      # optimized handlers for different token types
      
      # whitespace handler - skips all consecutive whitespace at once
      def handle_whitespace(_byte)
        @current += 1 while @current < @source_size && @is_whitespace[@source.getbyte(@current)]
      end
      
      # newline handler - increments line counter and skips consecutive newlines
      def handle_newline(_byte)
        @line += 1
        while @current < @source_size && @source.getbyte(@current) == B_NEWLINE
          @line += 1
          @current += 1
        end
      end
      
      # single line comment handler, skips to end of line in one operation
      def handle_single_line_comment(_byte)
        # byteindex, not index, index returns a CHARACTER offset, which would
        # silently desynchronise byte-based positions on non-ASCII lines.
        newline_pos = @source.byteindex("\n", @current)
        @current = newline_pos || @source_size
      end
      
      # multi-line comment handler for slash-star comments
      def handle_multi_line_comment
        @current += 1  # skip the '*' after '/'

        while @current < @source_size
          b = @source.getbyte(@current)

          if b == B_STAR && @current + 1 < @source_size && @source.getbyte(@current + 1) == B_SLASH
            @current += 2
            return
          end

          @line += 1 if b == B_NEWLINE
          @current += 1
        end
        Utils.lexing_error('Niezamkniety komentarz wieloliniowy', @line)
      end

      def handle_instance_var(_byte)
        b = peek_byte
        ascii_start  = b >= 0 && @is_alpha[b]
        polish_start = b >= POLISH_LEAD_MIN && b <= POLISH_LEAD_MAX &&
                       @current + 1 < @source_size &&
                       @is_polish_trail[b - POLISH_LEAD_MIN][@source.getbyte(@current + 1)]

        Utils.lexing_error('Oczekiwano identyfikatora po @', @line) unless ascii_start || polish_start

        @start = @current
        @current += (polish_start ? 2 : 1)

        while @current < @source_size
          nb = @source.getbyte(@current)
          if @is_alnum[nb]
            @current += 1
          elsif nb >= POLISH_LEAD_MIN && nb <= POLISH_LEAD_MAX &&
                @current + 1 < @source_size &&
                @is_polish_trail[nb - POLISH_LEAD_MIN][@source.getbyte(@current + 1)]
            @current += 2
          else
            break
          end
        end

        name = @source.byteslice(@start, @current - @start).force_encoding(Encoding::UTF_8)
        @tokens << Utils::Token.new(:tok_instance_var, name, @line)
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
        if next_match('*')
          add_token(:tok_power) 
        elsif next_match('=')
          add_token(:tok_stareq)
        else
          add_token(:tok_star)
        end
      end
      
      def handle_caret(char)
        add_token(:tok_caret)
      end

      def handle_tilde(char)
        add_token(:tok_tilde)
      end

      def handle_ampersand(char)
        add_token(:tok_bit_and)
      end

      def handle_pipe(char)
        add_token(:tok_bit_or)
      end
      
      def handle_mod(char)
        add_token(:tok_mod)
      end
      
      def handle_slash(char)
        if next_match('*')
          handle_multi_line_comment
        elsif next_match('/')
          add_token(:tok_intdiv)
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
        elsif next_match('>')
          add_token(:tok_rshift)          # >> — prawy shift
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
      def handle_numeral(byte)
        # Prefix literals: 0b1010 (binary), 0o777 (octal), 0xFF (hex)
        if byte == B_ZERO && @current < @source_size
          nb = @source.getbyte(@current)

          if nb == 98 || nb == 66          # b B
            @current += 1
            bin_start = @current
            while @current < @source_size
              d = @source.getbyte(@current)
              break unless d == 48 || d == 49
              @current += 1
            end
            Utils.lexing_error('Nieprawidlowy literal binarny', @line) if @current == bin_start
            lexeme = @source.byteslice(bin_start, @current - bin_start)
            @tokens << Utils::Token.new(:tok_int, lexeme.to_i(2).to_s, @line)
            return

          elsif nb == 120 || nb == 88      # x X
            @current += 1
            hex_start = @current
            @current += 1 while @current < @source_size && is_hex_digit?(@source.getbyte(@current))
            Utils.lexing_error('Nieprawidlowy literal szesnastkowy', @line) if @current == hex_start
            lexeme = @source.byteslice(hex_start, @current - hex_start)
            @tokens << Utils::Token.new(:tok_int, lexeme.to_i(16).to_s, @line)
            return

          elsif nb == 111 || nb == 79      # o O
            @current += 1
            oct_start = @current
            while @current < @source_size
              d = @source.getbyte(@current)
              break unless d >= B_ZERO && d <= B_SEVEN
              @current += 1
            end
            Utils.lexing_error('Nieprawidlowy literal osemkowy', @line) if @current == oct_start
            lexeme = @source.byteslice(oct_start, @current - oct_start)
            @tokens << Utils::Token.new(:tok_int, lexeme.to_i(8).to_s, @line)
            return
          end
        end

        # decimal path
        @current += 1 while @current < @source_size && @is_digit[@source.getbyte(@current)]

        if @current < @source_size && @source.getbyte(@current) == B_DOT &&
           @current + 1 < @source_size && @is_digit[@source.getbyte(@current + 1)]
          @current += 1
          @current += 1 while @current < @source_size && @is_digit[@source.getbyte(@current)]
          add_token(:tok_float)
        else
          add_token(:tok_int)
        end
      end
      
      # optimized identifier handler using precomputed keyword lookup
      def handle_identifier(_byte)
        while @current < @source_size
          b = @source.getbyte(@current)

          if @is_alnum[b]
            @current += 1
          elsif b >= POLISH_LEAD_MIN && b <= POLISH_LEAD_MAX &&
                @current + 1 < @source_size &&
                @is_polish_trail[b - POLISH_LEAD_MIN][@source.getbyte(@current + 1)]
            @current += 2
          else
            break
          end
        end

        word = @source.byteslice(@start, @current - @start).force_encoding(Encoding::UTF_8)
        @tokens << Utils::Token.new(@keywords[word] || :tok_identifier, word, @line)
      end


      # Entry point when an identifier starts with a Polish letter (imię, ćwiczenie).
      # tokenize! consumed the lead byte; validate and consume the trail byte,
      # then fall into the common identifier loop.
      def handle_polish_identifier(lead)
        trail = peek_byte
        handle_unknown(lead) unless trail >= 0 && @is_polish_trail[lead - POLISH_LEAD_MIN][trail]
        @current += 1
        handle_identifier(lead)
      end
      
      # optimized string handler with direct buffer access
      # Supports interpolation via #{expr} syntax (Ruby-style)
      def handle_string(quote_byte)
        @start += 1                 # skip the opening quote
        literal_start = @start
        interpolated = false

        while @current < @source_size
          b = @source.getbyte(@current)

          if b == B_BACKSLASH && @current + 1 < @source_size
            @current += 2           # escaped byte is consumed verbatim here and
            next                    # resolved later by apply_escapes
          end

          if b == B_HASH && @current + 1 < @source_size && @source.getbyte(@current + 1) == B_LCURLY
            emit_string_part(literal_start)
            @tokens << Utils::Token.new(:tok_interp_start, '#{', @line)
            interpolated = true

            @current += 2
            tokenize_interpolation_body

            literal_start = @current
            next
          end

          break if b == quote_byte

          @line += 1 if b == B_NEWLINE
          @current += 1
        end

        Utils.lexing_error('Niezakonczony ciag znakow', @line) if @current >= @source_size

        emit_string_part(literal_start)
        @current += 1               # skip closing quote
      end

      # Slices one literal segment and resolves its escape sequences. Both the
      # interpolated and non-interpolated paths go through here, so they cannot
      # diverge — previously the interpolated path processed escapes inline.
      def emit_string_part(from)
        text = @source.byteslice(from, @current - from).force_encoding(Encoding::UTF_8)
        @tokens << Utils::Token.new(:tok_string, apply_escapes(text), @line)
      end

      # Apply escape sequences to a raw string slice (used for non-interpolated path)
      def apply_escapes(text)
        text.gsub(/\\(.)/) do |_|
          process_escape($1)
        end
      end

      # Convert a single escape character to its actual value
      def process_escape(ch)
        case ch
        when 'n'  then "\n"
        when 't'  then "\t"
        when 'r'  then "\r"
        when '\\' then "\\"
        when '"'  then '"'
        when '\'' then "'"
        when '0'  then "\0"
        when '#'  then '#'   # escaped # to avoid interpolation
        else "\\#{ch}"        # unknown escape — preserve
        end
      end

      # Tokenize the body of #{...} — reuses main lexer logic but tracks brace depth
      # so we know when to stop and emit tok_interp_end
      def tokenize_interpolation_body
        depth = 1

        while @current < @source_size && depth > 0
          @start = @current
          b = @source.getbyte(@current)

          if b == B_LCURLY
            depth += 1
            @current += 1
            add_token(:tok_lcurly)
          elsif b == B_RCURLY
            depth -= 1
            @current += 1
            if depth == 0
              @tokens << Utils::Token.new(:tok_interp_end, '}', @line)
              return
            end
            add_token(:tok_rcurly)
          else
            @current += 1
            send(@dispatch_table[b], b)
          end
        end

        Utils.lexing_error("Niezakonczona interpolacja stringu (brakuje '}')", @line)
      end
      
      # handler for unknown characters
      def handle_unknown(byte)
        # A file saved in NFD encodes ś as s + U+0301, whose bytes start with
        # CC or CD. Naming that case explicitly saves the user from debugging a
        # file that looks correct in their editor.
        if byte == 0xCC || byte == 0xCD
          Utils.lexing_error('plik wydaje sie byc zapisany w formie NFD; zapisz go w UTF-8 NFC', @line)
        end

        char = @source.byteslice(@start, 4).force_encoding(Encoding::UTF_8).scrub('?')[0]
        Utils.lexing_error("nieznany znak: #{char}", @line)
      end
    end
  end
end