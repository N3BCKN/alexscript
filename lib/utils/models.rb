# frozen_string_literal: true

class Node
  def initialize(*)
    if self.class == BaseModel
      raise NotImplementedError, "BaseModel is an abstract class"
    end
  end

  private

  def validate_type(value, expected_type, param_name = 'value')
    return if value.is_a?(expected_type)
    raise TypeError, "Invalid #{param_name}: Expected #{expected_type}, got #{value.class}"
  end

  def validate_bool_type(value)
    return unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
    raise TypeError, "Invalid value: Expected boolean, got #{value.class}"
  end

  def indent(level)
    "  " * level
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
    validate_type(value, Integer)
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
    validate_type(value, Float)
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
    validate_type(value, String)
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
    validate_type(op, Token)
    validate_type(left, Expr)
    validate_type(right, Expr)
    @op = op
    @left = left
    @right = right
  end

  def pretty_print(level = 0)
  ["#{indent(level)}LogicalOp(#{@op.lexeme})",
    @left.pretty_print(level + 1),
    @right.pretty_print(level + 1)
  ].join("\n")
  end
end

# Examples: negation (-x), logical not (!x), bitwise complement (~x)
class UnOp < Expr
  attr_reader :op, :operand

  def initialize(op, operand, line)
    validate_type(op, Token, 'operator')
    validate_type(operand, Expr, 'operand')
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
    validate_type(op, Token, 'operator')
    validate_type(left, Expr, 'left operand')
    validate_type(right, Expr, 'right operand')
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
    validate_type(value, Expr, 'expression')
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


# Example: while (x < 10) { x = x + 1 }
class WhileStmt < Stmt
end


# Example: x = 42
class Assignment < Stmt
end