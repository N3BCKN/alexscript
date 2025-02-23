# frozen_string_literal: true

module AlexScript
  module AST
    class Node
      private

      def validate_types(values, expected_types, param_name = 'value')
        expected_types = [expected_types] unless expected_types.is_a?(Array)
        values = [values] unless values.is_a?(Array)

        values.each do |value|
          next if expected_types.any? { |type| value.is_a?(type) }

          # byebug
          expected = expected_types.map(&:name).join(' or ')
          raise TypeError, "Invalid #{param_name}: Expected #{expected}, got #{value.class}"
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

    # Declarations are statements to declare a new name for function or variable
    class Dclr < Stmt
    end

    # a list of all statements (each one of the belongs to the Statement class)
    class Stmts < Node
      attr_reader :stmts

      def initialize(stmts, line)
        @stmts = stmts || []
        validate_types(@stmts, [Stmt], 'expression') unless @stmts.empty?
        @line = line
      end

      def pretty_print(level = 0)
        statement_strings = []
        statement_strings << "#{indent(level)}Statements("

        @stmts.each do |stmt|
          statement_strings << stmt.pretty_print(level + 1)
        end

        statement_strings << "#{indent(level)})"
        statement_strings.join("\n")
      end
    end

    class ExpressionStmt < Stmt
      attr_reader :expression, :line

      def initialize(expression, line)
        validate_types([expression], [Expr])
        @expression = expression
        @line = line
      end

      def pretty_print(level = 0)
        ["#{indent(level)}ExpressionStmt(",
         @expression.pretty_print(level + 1),
         "#{indent(level)})"].join("\n")
      end
    end
  end
end
