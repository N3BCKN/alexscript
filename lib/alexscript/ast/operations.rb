# frozen_string_literal: true

module AlexScript
  module AST
    # Examples: addition (x + y), multiplication (x * y), comparison (x > y)
    class BinOp < Expr
      attr_reader :left, :right, :op, :line

      def initialize(op, left, right, line)
        validate_types([op], [Utils::Token], 'operator')
        validate_types([left], [Expr], 'left operand')
        validate_types([right], [Expr], 'right operand')
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

    # Examples: negation (-x), logical not (!x), bitwise complement (~x)
    class UnOp < Expr
      attr_reader :op, :operand

      def initialize(op, operand, line)
        validate_types([op], [Utils::Token], 'operator')
        validate_types([operand], [Expr], 'operand')
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

    class LogicalOp < Expr
      attr_reader :left, :right, :op

      def initialize(op, left, right, line)
        validate_types([op], [Utils::Token])
        validate_types([left, right], [Expr])

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

    # Example: (1 + 2) * 3
    class Grouping < Expr
      attr_reader :value

      def initialize(value, line)
        validate_types([value], [Expr], 'expression')
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

    # += -= *= /=
    class CompoundAssignment < Stmt
      attr_reader :left, :operator, :right, :line

      def initialize(left, operator, right, line)
        validate_types([left], [Identifier], 'left')
        validate_types([operator], [Utils::Token], 'operator')
        validate_types([right], [Expr], 'right')
        @left = left
        @operator = operator
        @right = right
        @line = line
      end

      def pretty_print(level = 0)
        ["#{indent(level)}CompoundAssignment(",
         "#{indent(level + 1)}left: #{@left.pretty_print(level + 1)}",
         "#{indent(level + 1)}operator: #{@operator.lexeme}",
         "#{indent(level + 1)}right: #{@right.pretty_print(level + 1)}",
         "#{indent(level)})"].join("\n")
      end
    end

    # example: tablica.dlg
    class MethodCall < Expr
      attr_reader :object, :method_name, :arguments, :line

      def initialize(object, method_name, arguments, line)
        validate_types([object], [Expr], 'object')
        validate_types([method_name], [String], 'method_name')
        validate_types(arguments, [Expr], 'arguments') unless arguments.nil?
        @object = object
        @method_name = method_name
        @arguments = arguments || []
        @line = line
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}MethodCall(",
          "#{indent(level + 1)}object: #{@object.pretty_print(level + 1)}",
          "#{indent(level + 1)}method: #{@method_name}",
          "#{indent(level + 1)}arguments: #{@arguments.map { |arg| arg.pretty_print(level + 2) }.join(', ')}",
          "#{indent(level)})"
        ].join("\n")
      end
    end

    class MethodCallStmt < Stmt
      attr_reader :expression, :line

      def initialize(expression, line)
        validate_types([expression], [Expr])
        @expression = expression
        @line = line
      end

      def pretty_print(level = 0)
        ["#{indent(level)}MethodCallStmt(",
         @expression.pretty_print(level + 1),
         "#{indent(level)})"].join("\n")
      end
    end
  end
end
