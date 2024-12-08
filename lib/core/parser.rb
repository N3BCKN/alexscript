# frozen_string_literal: true
require 'byebug'

# Parser class that builds an AST from tokens using recursive descent parsing
# Implements grammar rules for expressions, handling operator precedence and grouping
class Parser
  def initialize(tokens)
    @tokens = tokens
    @current = 0
  end
 
  # Advances the parser position and returns current token
  def advance
    token = @tokens[@current]
    @current += 1
    token
  end
 
  # Returns current token without advancing position
  def peek
    @tokens[@current]
  end
 
  # Checks if next token matches expected type
  def next?(expected_type)
    return false if @current >= @tokens.length
    peek.token_type == expected_type
  end
 
  # Expects a token of specific type, raises error if not found
  def expect(expected_type)
    if @current >= @tokens.length
      Utils.parse_error("Found '#{previous_token.lexeme}' at the end of parsing", previous_token.line)
      # raise SyntaxError, "Found '#{previous_token.lexeme}' at the end of parsing"
    elsif peek.token_type == expected_type
      advance
    else
      Utils.parse_error("Expected '#{expected_type}', found '#{peek.lexeme}'", peek.line)
      # raise SyntaxError, "Expected '#{expected_type}', found '#{peek.lexeme}'"
    end
  end
 
  # Returns the previously consumed token
  def previous_token
    @tokens[@current - 1]
  end
 
  # Matches and consumes token if it matches expected type
  def match(expected_type)
    return false if @current >= @tokens.length
    return false if peek.token_type != expected_type
    @current += 1  # Consume the token on match
    true
  end
 
  # Grammar rule: <primary> ::= <integer> | <float> | '(' <expr> ')' | <bool> | <string>
  # Handles basic expressions and parenthesized expressions
  def primary 
    return Int.new(previous_token.lexeme.to_i, previous_token.line) if match(:tok_int)
    return Flt.new(previous_token.lexeme.to_f, previous_token.line) if match(:tok_float)
    return Bool.new(previous_token.lexeme, previous_token.line) if match(:tok_true) || match(:tok_false)
    return Str.new(previous_token.lexeme.to_s, previous_token.line) if match(:tok_string)
    
    if match(:tok_lparen)
      expr = expression
      unless match(:tok_rparen)
        Utils.parse_error("Expected ')' after expression", previous_token.line)
      end
      return Grouping.new(expr, previous_token.line)
    end
 
    raise SyntaxError, "Expected expression"
  end
 
  # Grammar rule: <unary> ::= ('+'|'-'|'~') <unary> | <primary>
  # Handles unary operations like negation
  def unary
    if match(:tok_not) || match(:tok_minus) || match(:tok_plus)
      op = previous_token
      operand = unary
      return UnOp.new(op, operand, op.line)
    end
 
    primary
  end

  # Grammar rule: ::= <unary> ("^" <unary>)*
  def exponent
    expr = unary
 
    while match(:tok_caret)
      op = previous_token
      right = exponent
      expr = BinOp.new(op, expr, right, op.line)
    end

    expr  
  end

  # Grammar rule: <modulo> ::= <exponent> ("%" <exponent>)*
  def modulo
    expr = exponent
 
    while match(:tok_mod)
      op = previous_token
      right = exponent
      expr = BinOp.new(op, expr, right, op.line)
    end

    expr
  end
  
  # Grammar rule: <multiplication> ::= <modulo> ( ('*'|'/') <modulo> )*
  # Handles multiplication and division with proper precedence
  def multiplication
    expr = modulo
 
    while match(:tok_star) || match(:tok_slash)
      op = previous_token
      right = modulo
      expr = BinOp.new(op, expr, right, op.line)
    end
 
    expr
  end
 
  # Grammar rule: <addition> ::= <multiplication> ( ('+'|'-') <multiplication> )*
  # Handles addition and subtraction with proper precedence
  def addition
    expr = multiplication
 
    while match(:tok_plus) || match(:tok_minus)
      op = previous_token
      right = multiplication
      expr = BinOp.new(op, expr, right, op.line)
    end
 
    expr
  end

  #Grammar rule: <comparsion> ::= <addition> ((">" | ">=" | "<" | "<="))*
  def comparison
    expr = addition
    while match(:tok_greater) || match(:tok_greateroreq) || match(:tok_smalleroreq) || match(:tok_smaller)
      op = previous_token
      right = addition
      expr = BinOp.new(op, expr, right, op.line)
    end

    expr
  end

  #Grammar rule: <equality> ::= <comparsion>  ( ("~=" | "==")) <comparsion> 
  def equality
    expr = comparison
    while match(:tok_eq) || match(:tok_noteq)
      op = previous_token
      right = comparison
      expr = BinOp.new(op, expr, right, op.line)
    end

    expr
  end

  #Grammar rule: <logical_and> ::= <equality> ("and" <equality>)*
  def logical_and
    expr = equality
    while match(:tok_and)
      op = previous_token
      right = equality
      expr = LogicalOp.new(op, expr, right, op.line)
    end
  
    expr 
  end


  #Grammar rule: <logical_or> ::= <logical_and> ("or" <logical_and>)*
  def logical_or
    expr = logical_and
    while match(:tok_or)
      op = previous_token
      right = logical_and
      expr = LogicalOp.new(op, expr, right, op.line)
    end

    expr 
  end

  def expression
    logical_or
  end
 
  # Entry point for parsing, returns completed AST
  def parse!
    expression
  end
end