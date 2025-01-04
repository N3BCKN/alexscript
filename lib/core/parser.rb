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
    return Null.new(previous_token.line) if match(:tok_null)
    return array_statement if match(:tok_lsquare) # [ -> start array parsing

    if match(:tok_lparen) # (
      expr = expression
      Utils.parse_error("Expected ')' after expression", previous_token.line) unless match(:tok_rparen) # )
      return Grouping.new(expr, previous_token.line)
    end

    if match(:tok_lcurly) # {
      pairs = {}

      unless next?(:tok_rcurly)
        loop do
          # key is a string
          key = expect(:tok_string)
          expect(:tok_colon) # :
          value = expression
          pairs[key.lexeme] = value

          break unless match(:tok_comma)
        end
      end

      expect(:tok_rcurly) # }
      return ObjectLiteral.new(pairs, previous_token.line)
    end

    # handle function calls | array access | method calls
    identifier = expect(:tok_identifier)
    expr = Identifier.new(identifier.lexeme, identifier.line)

    loop do
      if match(:tok_lparen) # (
        f_args = arguments
        expect(:tok_rparen) # )
        expr = FuncCall.new(identifier.lexeme, f_args, previous_token.line)
        break
      elsif match(:tok_lsquare) # [ -> to access array element by calling its index, eg tablica[0]
        key = expression
        expect(:tok_rsquare) # ]
        if match(:tok_assign) # =
          value = expression
          # check if val is string (key to obj) or int (array index)
          if key.is_a?(Int)
            expr = ArrayAssignment.new(expr, key, value, identifier.line)
          elsif key.is_a?(Str)
            expr = ObjectAssignment.new(expr, key, value, identifier.line)
          else
            Utils.parse_error('Invalid key type - must be integer for arrays or string for objects',
                              previous_token.line)
          end
          break
        elsif key.is_a?(Int)
          # Podobnie dla dostępu
          expr = ArrayAccess.new(expr, key, identifier.line)
        elsif key.is_a?(Str)
          expr = ObjectAccess.new(expr, key, identifier.line)
        else
          Utils.parse_error('Invalid key type - must be integer for arrays or string for objects',
                            previous_token.line)
        end
      elsif match(:tok_dot) # . -> method calls
        method_name = expect(:tok_identifier).lexeme
        arguments = []
        if match(:tok_lparen) # (
          unless next?(:tok_rparen)
            loop do
              arguments << expression
              break unless match(:tok_comma)
            end
          end
          expect(:tok_rparen) # )
        end
        expr = MethodCall.new(expr, method_name, arguments, identifier.line)
      else
        break
      end
    end

    expr
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

  def array_statement
    elements = []

    # Parse array elements

    # handle empty arrays
    if next?(:tok_rsquare)
      advance
      return ArrayLiteral.new([], previous_token.line)
    end

    # iterate over array elements
    loop do
      elements << expression

      break unless match(:tok_comma)

      if next?(:tok_rsquare) # case: [1,2,]
        advance
        break
      end
    end

    expect(:tok_rsquare) # ]
    ArrayLiteral.new(elements, previous_token.line)
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

    if match(:tok_let) # standard loop for ranges
      identifier = primary
      expect(:tok_assign)
      start_statement = expression
      expect(:tok_semicolon)
      end_statement = expression
      step_statement = nil
      step_statement = expression if match(:tok_semicolon)
      expect(:tok_lcurly)
      body_statement = statements
      expect(:tok_rcurly)

      ForStmt.new(identifier, start_statement, end_statement, step_statement, body_statement, previous_token.line)
    else # loops for collections
      element_identifier = Identifier.new(expect(:tok_identifier).lexeme, previous_token.line)

      if match(:tok_comma) # for objects: dla klucz, wartosc w obj
        value_identifier = Identifier.new(expect(:tok_identifier).lexeme, previous_token.line)
        expect(:tok_in)
        object = expression
        expect(:tok_lcurly)
        body_statement = statements
        expect(:tok_rcurly)

        ForInObjectStmt.new(element_identifier, value_identifier, object, body_statement, previous_token.line)
      else # dla arrays: dla element w arr
        expect(:tok_in)
        collection = expression
        expect(:tok_lcurly)
        body_statement = statements
        expect(:tok_rcurly)

        ForInArrayStmt.new(element_identifier, collection, body_statement, previous_token.line)
      end
    end
  end

  # <loop_statement> ::= "petla" "{" <statement>*? "}"
  def loop_statement
    advance
    expect(:tok_lcurly) # {
    body_statement = statements
    expect(:tok_rcurly) # }
    LoopStmt.new(body_statement, previous_token.line)
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

  # <exit_statement> ::= "wyjscie" "(" <expression>? ")"
  def exit_statement
    advance
    expect(:tok_lparen) # (
    message = expression unless next?(:tok_rparen)
    expect(:tok_rparen) # (

    ExitStmt.new(message, previous_token.line)
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
    # elsif token == :tok_null
    #   Null.new(previous_token.line)
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
    elsif token == :tok_loop
      loop_statement
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
    elsif token == :tok_exit
      exit_statement
    elsif token == :tok_local
      local_assign
    else
      left = expression
      if match(:tok_assign)
        right = expression
        Assignment.new(left, right, previous_token.line)
      elsif left.is_a?(FuncCall)
        # handle function calls and array access statements
        FuncCallStmt.new(left, previous_token.line)
      elsif left.is_a?(ArrayAccess)
        ArrayAccessStmt.new(left, previous_token.line)
      elsif left.is_a?(ArrayAssignment)
        ArrayAssignmentStmt.new(left, previous_token.line)
      elsif left.is_a?(MethodCall)
        MethodCallStmt.new(left, previous_token.line)
      elsif left.is_a?(Expr)
        ExpressionStmt.new(left, previous_token.line)
      else
        Utils.parse_error('Unexpected expression', previous_token.line)
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
