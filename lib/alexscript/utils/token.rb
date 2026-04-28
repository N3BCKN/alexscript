# frozen_string_literal: true

require 'set'

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

    # Single source of truth for Polish keyword lexemes and their tokens.
    # Used by Lexer (lexeme -> token) and Parser (token -> lexeme, for error messages).
    # Frozen: allocated once at load time, shared across all Lexer/Parser instances.
    KEYWORDS = {
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
      'statyczna' => :tok_static,
      'prywatne' => :tok_private,
      'abstrakcyjna' => :tok_abstract,
      'require_ruby' => :tok_require_ruby,
      'modul' => :tok_module,
      'dolacz' => :tok_include,
      'debug' => :tok_debug,
      'fn' => :tok_fn,
      'asynchroniczna' => :tok_async,
      'czekaj' => :tok_await,
      'istnieje' => :tok_exists
    }.freeze

    # Tokens that are keywords in expression position but valid as names
    # (method names, function/class names, module member names, etc.).
    # Adding a token here means it can be used as: obj.NAME, NAME.foo,
    # Modul::NAME, funkcja NAME() {}, klasa Foo { funkcja NAME() {} }.
    # It does NOT make the token valid as a variable name (niech NAME = ...);
    # variables and the keyword's expression-position meaning would conflict.
    SOFT_KEYWORDS = Set[
      :tok_exists,
      :tok_class,   
      :tok_null,    
      :tok_true,    
      :tok_false,   
      :tok_for,     
      :tok_in       
    ].freeze

    # Set of keyword tokens for O(1) membership checks in the parser.
    # Materialized once from KEYWORDS.values.
    KEYWORD_TOKENS = KEYWORDS.values.to_set.freeze
  end
end
