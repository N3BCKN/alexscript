# frozen_string_literal: true

module AlexScript
  module AST
    class Node
      # Default evaluator — raised if a subclass didn't implement its own.
      # During the migration from the interpret! if-elsif chain to method
      # dispatch, any AST node whose class doesn't implement evaluate
      # will land here with a loud, actionable error instead of silent
      # misbehaviour.
      def evaluate(_interpreter, _env)
        raise NotImplementedError,
              "AST node #{self.class.name} does not implement evaluate(interpreter, env)."
      end

      private

      def validate_types(values, expected_types, param_name = 'value')
        expected_types = [expected_types] unless expected_types.is_a?(Array)
        values = [values] unless values.is_a?(Array)

        values.each do |value|
          next if expected_types.any? { |type| value.is_a?(type) }

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

      def evaluate(interpreter, env)
        i = 0
        while i < @stmts.size
          interpreter.interpret!(@stmts[i], env)
          i += 1
        end
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

      def evaluate(interpreter, env)
        interpreter.interpret!(@expression, env)
      end

      def pretty_print(level = 0)
        ["#{indent(level)}ExpressionStmt(",
         @expression.pretty_print(level + 1),
         "#{indent(level)})"].join("\n")
      end
    end
  end
end