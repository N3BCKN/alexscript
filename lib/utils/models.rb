# frozen_string_literal: true

require('byebug')

class Node
  private

  def validate_types(values, expected_type, param_name = 'value')
    values = [values] unless values.is_a?(Array)

    i = 0
    while i < values.length
      value = values[i]
      unless value.is_a?(expected_type)
        raise TypeError, "Invalid #{param_name}: Expected #{expected_type}, got #{value.class}"
      end

      i += 1
    end
  end

  def validate_bool_type(value)
    return unless value.is_a?(TrueClass) || value.is_a?(FalseClass)

    raise TypeError, "Invalid value: Expected boolean, got #{value.class}"
  end

  def indent(level)
    '  ' * level
  end
end

# Abstract base class for all statements in the AST
# Statements are language constructs that perform actions but don't return values
# Examples: variable declarations, assignments, control flow statements
class Stmt < Node
end

# Abstract base class for all expressions in the AST
# Expressions are language constructs that can be evaluated to produce a value
# Examples: arithmetic operations, function calls, literals
class Expr < Node
end

# Example: 42 in the expression "x = 42"
class Int < Expr
  attr_reader :value

  def initialize(value, line)
    validate_types([value], Integer)
    @value = value
    @line  = line
  end

  def pretty_print(level = 0)
    "#{indent(level)}Int(#{@value})"
  end
end

# Example: 3.14 in the expression "pi = 3.14"
class Flt < Expr
  attr_reader :value

  def initialize(value, line)
    validate_types([value], Float)
    @value = value
    @line  = line
  end

  def pretty_print(level = 0)
    "#{indent(level)}Float(#{@value})"
  end
end

# Example: true, false
class Bool < Expr
  attr_reader :value

  def initialize(value, line)
    validate_bool_type(value)
    @value = value
    @line = line
  end

  def pretty_print(level = 0)
    "#{indent(level)}Bool(#{@value})"
  end
end

# Example: 'this is a string', "this is a string"
class Str < Expr
  attr_reader :value

  def initialize(value, line)
    validate_types([value], String)
    @value = value
    @line = line
  end

  def pretty_print(level = 0)
    "#{indent(level)}String(#{@value})"
  end
end

class LogicalOp < Expr
  attr_reader :left, :right, :op

  def initialize(op, left, right, line)
    validate_types([op], Token)
    validate_types([left, right], Expr)

    @op = op
    @left = left
    @right = right
  end

  def pretty_print(level = 0)
    ["#{indent(level)}LogicalOp(#{@op.lexeme})",
     @left.pretty_print(level + 1),
     @right.pretty_print(level + 1)].join("\n")
  end
end

# Examples: negation (-x), logical not (!x), bitwise complement (~x)
class UnOp < Expr
  attr_reader :op, :operand

  def initialize(op, operand, line)
    validate_types([op], Token, 'operator')
    validate_types([operand], Expr, 'operand')
    @op      = op
    @operand = operand
    @line    = line
  end

  def pretty_print(level = 0)
    [
      "#{indent(level)}UnaryOp(#{@op.lexeme})",
      @operand.pretty_print(level + 1)
    ].join("\n")
  end
end

# Examples: addition (x + y), multiplication (x * y), comparison (x > y)
class BinOp < Expr
  attr_reader :left, :right, :op

  def initialize(op, left, right, line)
    validate_types([op], Token, 'operator')
    validate_types([left], Expr, 'left operand')
    validate_types([right], Expr, 'right operand')
    @op    = op
    @left  = left
    @right = right
    @line  = line
  end

  def pretty_print(level = 0)
    [
      "#{indent(level)}BinaryOp(#{@op.lexeme})",
      @left.pretty_print(level + 1),
      @right.pretty_print(level + 1)
    ].join("\n")
  end
end

# Example: (1 + 2) * 3
class Grouping < Expr
  attr_reader :value

  def initialize(value, line)
    validate_types([value], Expr, 'expression')
    @value = value
    @line  = line
  end

  def pretty_print(level = 0)
    [
      "#{indent(level)}Group(",
      @value.pretty_print(level + 1),
      "#{indent(level)})"
    ].join("\n")
  end
end

# a list of all statements (each one of the belongs to the Statement class)
class Stmts < Node
  attr_reader :stmts

  def initialize(stmts, line)
    validate_types(stmts, Stmt, 'expression')
    @stmts = stmts
    @line = line
  end

  def pretty_print(level = 0)
    statement_strings = []
    statement_strings << "#{indent(level)}Statements("

    i = 0
    while i < @stmts.length
      statement_strings << @stmts[i].pretty_print(level + 1)
      i += 1
    end

    statement_strings << "#{indent(level)})"
    statement_strings.join("\n")
  end
end

# print value (pokaz ...)
class PrintStmt < Stmt
  attr_reader :value, :ending

  def initialize(value, line)
    validate_types([value], Expr, 'expression')
    @value = value
    @line = line
  end

  def pretty_print(level = 0)
    [
      "#{indent(level)}PrintStatement(",
      @value.pretty_print(level + 1),
      "#{indent(level)})"
    ].join("\n")
  end
end

# jesli/albojesli/albo
class IfStmt < Stmt
  attr_reader :test, :then_stmt, :else_stmt

  def initialize(test, then_stmt, else_stmt, line)
    validate_types([test], Expr)
    validate_types([then_stmt], Stmts)
    # TODO: validate else statement as statement or nil, new method perhaps?

    @test = test
    @then_stmt = then_stmt
    @else_stmt = else_stmt
    @line = line
  end

  def pretty_print(level = 0)
    else_stmt_expression = @else_stmt ? "else: #{@else_stmt.pretty_print(level + 1)}" : ''
    [
      "#{indent(level)}IfStatement(",
      "test: #{@test.pretty_print}}",
      @then_stmt.pretty_print(level + 1),
      else_stmt_expression,
      "#{indent(level)})"
    ].join("\n")
  end
end

# Example: dopoki x <= n {<body_statement>*}
class WhileStmt < Stmt
  attr_reader :test, :body_statement, :line

  def initialize(test, body_statement, line)
    validate_types([test], Expr)
    validate_types([body_statement], Stmts)
    @test = test
    @body_statement = body_statement
    @line = line # dodajemy przypisanie line!
  end

  def pretty_print(level = 0)
    [
      "#{indent(level)}While(",
      @test.pretty_print(level + 1),
      @body_statement.pretty_print(level + 1),
      "#{indent(level)})"
    ].join("\n")
  end
end

# Example: niech x = 42
class Assignment < Stmt
  attr_reader :left, :right

  def initialize(left, right, line)
    validate_types([left, right], Expr)
    @left = left
    @right = right
    @line = line
  end

  def pretty_print(level = 0)
    [
      "#{indent(level)}Assignment(",
      @left.pretty_print(level + 1),
      @right.pretty_print(level + 1),
      "#{indent(level)})"
    ].join("\n")
  end
end

class Identifier < Expr
  attr_reader :name, :line

  def initialize(name, line)
    @name = name
    @line = line
  end

  def pretty_print(level = 0)
    "#{indent(level)}Identifier(#{@name})"
  end
end
