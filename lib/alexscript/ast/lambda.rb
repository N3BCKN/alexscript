# frozen_string_literal: true

module AlexScript
  module AST
    # fn(params) { body } — anonymous function expression
    # Inherits from Expr (not Dclr) because lambdas are values, not declarations
    class LambdaExpr < Expr
      attr_reader :params, :body_statement, :line

      # Frozen label for stack traces — single allocation, shared across all instances
      FN_NAME = '<fn>'.freeze

      def initialize(params, body_statement, line)
        @params = params
        @body_statement = body_statement
        @line = line
        # cache implicit return check at parse time — avoids repeated computation at runtime
        stmt = body_statement.stmts[0]
        @_implicit = body_statement.stmts.size == 1 &&
                    (stmt.is_a?(ExpressionStmt) || 
                      stmt.is_a?(FuncCallStmt) || 
                      stmt.is_a?(MethodCallStmt))
      end

      def name
        FN_NAME
      end

      def implicit_return?
        @_implicit
      end

      def pretty_print(level = 0)
        params_str = @params.map { |p| p.name }.join(', ')
        [
          "#{indent(level)}LambdaExpr(#{params_str})",
          @body_statement.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # fn(x) { x }(args) — immediate invocation or calling any expression that evaluates to a function
    class LambdaCall < Expr
      attr_reader :callee, :arguments, :line

      def initialize(callee, arguments, line)
        @callee = callee
        @arguments = arguments
        @line = line
      end

      def pretty_print(level = 0)
        args_str = @arguments.map { |a| a.pretty_print(level + 1) }.join("\n")
        [
          "#{indent(level)}LambdaCall(",
          @callee.pretty_print(level + 1),
          args_str,
          "#{indent(level)})"
        ].join("\n")
      end
    end
  end
end