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

    @current += 1 # Consume the token on match
    true
  end

  # <primary> ::= <integer> | <float> | '(' <expr> ')' | <bool> | <string> | <identifier>
  # Handles basic expressions and parenthesized expressions
  def primary
    return Int.new(previous_token.lexeme.to_i, previous_token.line) if match(:tok_int)
    return Flt.new(previous_token.lexeme.to_f, previous_token.line) if match(:tok_float)
    return Bool.new(previous_token.lexeme, previous_token.line) if match(:tok_true) || match(:tok_false)
    return Str.new(previous_token.lexeme.to_s, previous_token.line) if match(:tok_string)

    if match(:tok_lparen)
      expr = expression
      Utils.parse_error("Expected ')' after expression", previous_token.line) unless match(:tok_rparen)
      return Grouping.new(expr, previous_token.line)
    end

    # handle function calls
    identifier = expect(:tok_identifier)
    if match(:tok_lparen) # (
      f_args = arguments
      expect(:tok_rparen) # )
      FuncCall.new(identifier.lexeme, f_args, previous_token.line)
    else
      Identifier.new(identifier.lexeme, previous_token.line)
    end

    # TODO: we can also have action calls here and hande this as well

    # raise SyntaxError, 'Expected expression'
  end

  # <unary> ::= ('+'|'-'|'~') <unary> | <primary>
  # Handles unary operations like negation
  def unary
    if match(:tok_not) || match(:tok_minus) || match(:tok_plus)
      op = previous_token
      operand = unary
      return UnOp.new(op, operand, op.line)
    end

    primary
  end

  # ::= <unary> ("^" <unary>)*
  def exponent
    expr = unary

    while match(:tok_caret)
      op = previous_token
      right = exponent
      expr = BinOp.new(op, expr, right, op.line)
    end

    expr
  end

  # <modulo> ::= <exponent> ("%" <exponent>)*
  def modulo
    expr = exponent

    while match(:tok_mod)
      op = previous_token
      right = exponent
      expr = BinOp.new(op, expr, right, op.line)
    end

    expr
  end

  # <multiplication> ::= <modulo> ( ('*'|'/') <modulo> )*
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

  # <addition> ::= <multiplication> ( ('+'|'-') <multiplication> )*
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

  # <comparsion> ::= <addition> ((">" | ">=" | "<" | "<="))*
  def comparison
    expr = addition
    while match(:tok_greater) || match(:tok_greateroreq) || match(:tok_smalleroreq) || match(:tok_smaller)
      op = previous_token
      right = addition
      expr = BinOp.new(op, expr, right, op.line)
    end

    expr
  end

  # <equality> ::= <comparsion>  ( ("~=" | "==")) <comparsion>
  def equality
    expr = comparison
    while match(:tok_eq) || match(:tok_noteq)
      op = previous_token
      right = comparison
      expr = BinOp.new(op, expr, right, op.line)
    end

    expr
  end

  # <logical_and> ::= <equality> ("and" <equality>)*
  def logical_and
    expr = equality
    while match(:tok_and)
      op = previous_token
      right = equality
      expr = LogicalOp.new(op, expr, right, op.line)
    end

    expr
  end

  # <logical_or> ::= <logical_and> ("or" <logical_and>)*
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

  # <print_statement> :== "pokaz" <expression>
  def print_statement
    return unless match(:tok_print)

    value = expression
    PrintStmt.new(value, previous_token.line)
  end

  # <println_statement> :== "pokazl" <expression>
  def println_statement
    return unless match(:tok_println)

    value = expression
    PrintlnStmt.new(value, previous_token.line)
  end

  # <if_statement> ::= "jesli" <expression> "albojesli" <stmts>*? {<stmts> "albo" <stmts>}?
  def if_statement
    expect(:tok_if)
    test = expression

    if next?(:tok_then) # if ... then ... statement
      advance
      then_stmt = statement
      OneLinerIfStmt.new(test, then_stmt, previous_token.line)
    else
      expect(:tok_lcurly) # {
      then_stmt = statements
      expect(:tok_rcurly) # }
      else_if_conditions = []

      while next?(:tok_elseif)
        advance
        else_if_test = expression
        expect(:tok_lcurly) # {
        else_if_stmt = statements
        expect(:tok_rcurly) # }
        else_if_conditions << [else_if_test, else_if_stmt]
      end

      if next?(:tok_else)
        advance # consume else
        expect(:tok_lcurly)
        else_stmts = statements
        expect(:tok_rcurly)
      else
        else_stmts = nil
      end

      IfStmt.new(test, then_stmt, else_stmts, else_if_conditions, previous_token.line)
    end
  end

  def while_statement
    expect(:tok_while)
    test = expression
    expect(:tok_lcurly) # {
    body_statement = statements
    expect(:tok_rcurly) # }

    WhileStmt.new(test, body_statement, previous_token.line)
  end

  # <for_statement> :== "dla" <identifier> "=" <start> ";" <end> (";" <increment>)? "{" <body_statement> "]"
  def for_statement
    expect(:tok_for)
    expect(:tok_let)
    identifier = primary
    expect(:tok_assign)
    start_statement = expression
    expect(:tok_semicolon)
    end_statement = expression
    if next?(:tok_semicolon)
      advance
      step_statment = expression
    end
    expect(:tok_lcurly) # {
    body_statement = statements
    expect(:tok_rcurly) # }

    ForStmt.new(identifier, start_statement, end_statement, step_statment, body_statement, previous_token.line)
  end

  # <func_decl> :== "funkcja" <name> "(" <params>? ")" "{" <body_stmts> "}"
  def func_decl
    expect(:tok_func)
    name = expect(:tok_identifier)
    expect(:tok_lparen) # (
    f_params = params
    expect(:tok_rparen) # )
    expect(:tok_lcurly) # {
    body_statement = statements
    expect(:tok_rcurly) # }

    FuncDclr.new(name.lexeme, f_params, body_statement, previous_token.line)
  end

  # <local_assign> ::= "lokalna" <asign>
  def local_assign
    expect(:tok_local)
    left = expression
    expect(:tok_assign)
    right = expression
    LocalAssignment.new(left, right, previous_token.line)
  end

  # <arguments> :== <expr> (',' <expr>)*
  def arguments
    f_args = []
    until next?(:tok_rparen)
      f_args << expression
      expect(:tok_comma) unless next?(:tok_rparen)
    end
    f_args
  end

  # <params> :== <identifier> (',' <identifier>)*
  def params
    f_params = []
    params_num = 0
    until next?(:tok_rparen)
      params_num += 1
      Utils.parse_error('Number of params in function exceeded 255', previous_token.line) if params_num > 255
      name = expect(:tok_identifier)
      f_params << Param.new(name.lexeme, previous_token.line)
      expect(:tok_comma) unless next?(:tok_rparen)
    end
    f_params
  end

  # <return_stmt> :== "zwroc" <expression>
  def return_statement
    expect(:tok_return)
    value = expression
    ReturnStatement.new(value, previous_token.line)
  end

  # <variable_statment> :== "niech" <expression> <assign> "=" <expression>
  def var_declaration_statement
    expect(:tok_let)
    left = expression
    expect(:tok_assign)
    right = expression
    VariableDeclaration.new(left, right, previous_token.line)
  end

  # <global_variable_statment> :== "globalna" "niech" <expression> <assign> "=" <expression>
  def global_var_declaration_statement
    expect(:tok_global)
    expect(:tok_let)
    left = expression
    expect(:tok_assign)
    right = expression
    GlobalVariableDeclaration.new(left, right, previous_token.line)
  end

  def statement
    # predict next token
    token = peek.token_type
    if token == :tok_let
      var_declaration_statement
    elsif token == :tok_global
      global_var_declaration_statement
    elsif token == :tok_print
      print_statement
    elsif token == :tok_println
      println_statement
    elsif token == :tok_if
      if_statement
    elsif token == :tok_while
      while_statement
    elsif token == :tok_for
      for_statement
    elsif token == :tok_break
      advance
      BreakLoop.new(previous_token.line)
    elsif token == :tok_continue
      advance
      ContinueLoop.new(previous_token.line)
    elsif token == :tok_func
      func_decl
    elsif token == :tok_return
      return_statement
    elsif token == :tok_local
      local_assign
    else
      left = expression
      if match(:tok_assign)
        right = expression
        Assignment.new(left, right, previous_token.line)
      else
        # handle function call statements, eg: myfunction()
        FuncCallStmt.new(left, previous_token.line)
      end
    end
  end

  def statements
    stmts = []
    stmts << statement while @current < @tokens.size && !next?(:tok_rcurly)
    Stmts.new(stmts, previous_token.line) unless stmts.empty?
  end

  # <program> ::= <statements>*
  def program
    statements
  end

  # Entry point for parsing, returns completed AST
  def parse!
    program
  end
end
