# frozen_string_literal: true

module AlexScript
  module AST
    # fn(params) { body } — anonymous function expression
    # Inherits from Expr (not Dclr) because lambdas are values, not declarations
    class LambdaExpr < Expr
      attr_reader :params, :body_statement, :line, :async
      # Same precomputed param metadata as FuncDclr — see FuncDclr#initialize
      # for rationale.
      attr_reader :rest_param, :rest_idx, :normal_params, :min_args, :max_args

      # Frozen label for stack traces — single allocation, shared across all instances
      FN_NAME = '<fn>'.freeze

      def initialize(params, body_statement, line, async: false)
        @params = params
        @body_statement = body_statement
        @line = line
        @async = async
        # cache implicit return check at parse time — avoids repeated computation at runtime
        stmt = body_statement.stmts[0]
        @_implicit = body_statement.stmts.size == 1 &&
                    (stmt.is_a?(ExpressionStmt) || 
                      stmt.is_a?(FuncCallStmt) || 
                      stmt.is_a?(MethodCallStmt))

        # Precompute param metadata; mirrors FuncDclr.
        params_arr = @params || []
        @rest_param    = params_arr.find(&:rest?)
        @rest_idx      = @rest_param ? params_arr.index(&:rest?) : nil
        @normal_params = @rest_param ? params_arr.reject(&:rest?) : params_arr
        @min_args      = params_arr.count { |p| !p.has_default? && !p.rest? }
        @max_args      = @rest_param ? Float::INFINITY : params_arr.size
      end

      def name
        FN_NAME
      end

      def implicit_return?
        @_implicit
      end

      # LambdaExpr is always a user-defined fn; it never wraps a native Ruby
      # proc. Provide the accessor anyway so dispatch sites can call it
      # uniformly with FuncDclr instead of using respond_to?.
      def native_lambda
        nil
      end

      def evaluate(_interpreter, env)
        # fn(params) { body } — capture current env as closure (direct ref, not WeakRef)
        [:type_function, { declaration: self, env: env }]
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

      def evaluate(interpreter, env)
        callee_type, callee_value = interpreter.interpret!(@callee, env)

        unless callee_type == :type_function
          Utils.runtime_error("Próba wywołania wartości niebędącej funkcją", @line)
        end

        func_declr = callee_value[:declaration]
        func_env = callee_value[:env]


        # Some :type_function values wrap a Ruby proc instead of an AS body.
        # Used for resolve/reject callbacks passed to Obietnica.nowa executors
        if func_declr.native_lambda
          arguments = @arguments.map { |arg| interpreter.interpret!(arg, env) }
          result = func_declr.native_lambda.call(*arguments)
          # Native lambda returns a tagged tuple [type, value] directly.
          # If it returned nil (fire-and-forget style), synthesize :type_null.
          return result if result.is_a?(Array) && result.size == 2 && result[0].is_a?(Symbol)
          return [:type_null, Utils::NULL_VALUE]
        end


        call_name = func_declr.respond_to?(:name) ? func_declr.name : '<fn>'

        # Validate argument count — read precomputed metadata from declaration
        rest_param = func_declr.rest_param
        min_args = func_declr.min_args

        if @arguments.size < min_args
          Utils.runtime_error(
            "Funkcja #{call_name} oczekiwała minimum #{min_args} argumentów, otrzymała #{@arguments.size}",
            @line
          )
        end

        unless rest_param
          max_args = func_declr.max_args
          if @arguments.size > max_args
            Utils.runtime_error(
              "Funkcja #{call_name} oczekiwała maksymalnie #{max_args} argumentów, otrzymała #{@arguments.size}",
              @line
            )
          end
        end

        # Evaluate arguments
        arguments = @arguments.map do |arg|
          if arg.is_a?(AST::Identifier)
            var = env.get_var(arg.name)
            if var
              [var[:type], var[:value]]
            else
              func_value = env.get_func_as_value(arg.name)
              Utils.runtime_error("Niezdefiniowana zmienna lub funkcja #{arg.name}", arg.line) unless func_value
              func_value
            end
          else
            interpreter.interpret!(arg, env)
          end
        end

        # Create execution environment from closure env
        new_func_env = func_env.new_env

        # Propagate instance context for fn used inside class methods
        current_instance = env.get_instance
        new_func_env.set_instance(current_instance) if current_instance

        # Assign parameters
        rest_idx = func_declr.rest_idx
        rest_position = rest_idx || func_declr.params.size

        normal_params = func_declr.normal_params
        normal_params.each_with_index do |param, idx|
          if idx < arguments.size && (rest_idx.nil? || idx < rest_idx)
            new_func_env.set_local_var(param.name, arguments[idx][1], arguments[idx][0])
          elsif param.has_default?
            default_value = interpreter.interpret!(param.default_value, func_env)
            new_func_env.set_local_var(param.name, default_value[1], default_value[0])
          else
            Utils.runtime_error("Brakujący argument #{param.name}", @line)
          end
        end

        if rest_param
          rest_args = arguments[rest_position..-1] || []
          rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
          new_func_env.set_local_var(rest_param.name, rest_array_elements, :type_array)
        end

        # Execute body
        env.increment_call_depth(@line)
        Utils::CallStackTracker.push(:function, call_name, @current_file, @line)
        result = catch(:alex_return) do
          begin
            Utils::ContextTracker.track_method_call(call_name) do
              if func_declr.implicit_return?
                interpreter.interpret!(func_declr.body_statement.stmts[0].expression, new_func_env)
              else
                interpreter.interpret!(func_declr.body_statement, new_func_env)
                [:type_null, Utils::NULL_VALUE]
              end
            end
          ensure
            Utils::CallStackTracker.pop
          end
        end
        env.decrement_call_depth
        result
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