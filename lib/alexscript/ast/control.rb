# frozen_string_literal: true

module AlexScript
  module AST
    # jesli/albojesli/albo
    class IfStmt < Stmt
      attr_reader :test, :then_stmt, :else_stmt, :else_if_conditions, :line

      def initialize(test, then_stmt, else_stmt, else_if_conditions, line)
        validate_types([test], [Expr])
        validate_types([then_stmt], [Stmts])
        validate_types([else_stmt], [Stmts]) unless else_stmt.nil?
        validate_types([else_if_conditions], Array) unless else_if_conditions.nil?

        @test = test
        @then_stmt = then_stmt
        @else_stmt = else_stmt
        @else_if_conditions = else_if_conditions
        @line = line
      end

      def evaluate(interpreter, env)
        test_type, test_value = interpreter.interpret!(@test, env)

        if interpreter.is_truthy?(test_type, test_value, @line)
          interpreter.interpret!(@then_stmt, env.new_env)
        else
          # check else-if statements
          executed = false
          @else_if_conditions.each do |condition|
            else_if_test, else_if_stmt = condition
            else_if_type, else_if_value = interpreter.interpret!(else_if_test, env)

            next unless interpreter.is_truthy?(else_if_type, else_if_value, @line)

            interpreter.interpret!(else_if_stmt, env.new_env)
            executed = true
            break
          end
          # if no other condition was fullfiled, execute else (albo) statement
          interpreter.interpret!(@else_stmt, env.new_env) if !executed && @else_stmt
        end
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

    # jesli x to ...
    class OneLinerIfStmt < Stmt
      attr_reader :test, :then_stmt, :line

      def initialize(test, then_stmt, line)
        validate_types([test], [Expr])
        validate_types([then_stmt], [Stmt])
        @test = test
        @then_stmt = then_stmt
        @line = line
      end

      def evaluate(interpreter, env)
        test_type, test_value = interpreter.interpret!(@test, env)
        interpreter.interpret!(@then_stmt, env) if interpreter.is_truthy?(test_type, test_value, @line)
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}OneLinerIf(",
          "test: #{@test.pretty_print(level + 1)}",
          "then: #{@then_stmt.pretty_print(level + 1)}",
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # debug()
    class DebugBreak < Stmt
      attr_reader :line

      def initialize(line)
        @line = line
      end

      def evaluate(interpreter, env)
        Utils::Debugger.activate!(self, env, interpreter)
      end

      def pretty_print(level = 0)
        "#{indent(level)}DebugBreak(line: #{@line})"
      end
    end
  end
end