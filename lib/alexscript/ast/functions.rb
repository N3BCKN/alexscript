# frozen_string_literal: true

module AlexScript
  module AST
    # "funkcja" <name> "(" <params>? ")" "{" <body_stmts> "}"
    class FuncDclr < Dclr
      attr_reader :name, :params, :body_statement, :line

      def initialize(name, params, body_statement, line)
        validate_types([name], [String])
        validate_types(params, [Param]) unless params.nil? # TODO: dobule check this
        validate_types([body_statement], Stmts)

        @name = name
        @params = params
        @body_statement = body_statement
        @line = line
        @private = false 
      end

      def set_private(is_private)
        @private = is_private
      end
    
      def private?
        @private
      end

      def pretty_print(level = 0)
        function_string = []
        function_string << "#{indent(level)}FunctionDeclaration(#{@private ? 'private ' : ''}"
        function_string << "#{indent(level)} name: #{@name}"
        # function_string[0] = "#{indent(level)}FunctionDeclaration(#{@private ? 'private ' : ''}"

        i = 0
        while i < @params.length
          function_string << @params[i].pretty_print(level + 1)
          i += 1
        end

        function_string << @body_statement.pretty_print(level = 1)

        function_string << "#{indent(level)})"
        function_string.join("\n")
      end
    end

    # single function parameter
    class Param < Dclr
      attr_reader :name, :default_value, :line, :rest

      def initialize(name, line, default_value = nil, rest = false)
        validate_types([name], [String])
        @name = name
        @line = line
        @default_value = default_value
        @rest = rest
      end

      def has_default?
        !@default_value.nil?
      end
      
      def rest?
        @rest
      end

      def pretty_print(level = 0)
        rest_str = @rest ? "*" : ""
        if @default_value
          "#{indent(level)}Param(#{rest_str}#{@name}, default=#{@default_value.pretty_print(0)})"
        else
          "#{indent(level)}Param(#{rest_str}#{@name})"
        end
      end
    end

    # <func_call> :== <name> "(" <args>? ")"
    # <args> :== <expr> (',' <expr>)*
    class FuncCall < Expr
      attr_reader :name, :arguments, :line

      def initialize(name, arguments, line)
        validate_types([name], [String])
        validate_types(arguments, Expr) unless arguments.empty? # TODO: dobule check this
        @name = name
        @arguments = arguments
        @line = line
      end

      def pretty_print(level = 0)
        arguments_strings = []
        arguments_strings << "#{indent(level)}FunctionCall("
        arguments_strings << "#{indent(level)} name: #{@name}"

        i = 0
        while i < @arguments.length
          arguments_strings << @arguments[i].pretty_print(level + 1)
          i += 1
        end

        arguments_strings << "#{indent(level)})"
        arguments_strings.join("\n")
      end
    end

    # a special type of statement used to wrap FuncCall expressions, eg. myfucntion()
    class FuncCallStmt < Stmt
      attr_reader :expression, :line

      def initialize(expression, line)
        validate_types([expression], [FuncCall])
        @expression = expression
        @line = line
      end

      def pretty_print(level = 0)
        ["#{indent(level)}FuncCallStmt(",
         @expression.pretty_print(level + 1)].join("\n")
      end
    end

    # "zwroc" <exprs>
    class ReturnStatement < Stmt
      attr_reader :value, :line

      def initialize(value, line)
        validate_types([value], [Expr])
        @value = value
        @line = line
      end

      def pretty_print(level = 0)
        ["#{indent(level)}Return(",
         @value.pretty_print(level + 1),
         "#{indent(level)})"].join("\n")
      end
    end
    
    class InstanceMethodCall < Expr
      attr_reader :object, :method_name, :arguments, :line

      def initialize(object, method_name, arguments, line)
        validate_types([object], [Expr])
        validate_types([method_name], [String])
        @object = object
        @method_name = method_name
        @arguments = arguments || []
        @line = line
      end

      def pretty_print(level = 0)
        args_str = @arguments.map { |arg| arg.pretty_print(level + 2) }.join("\n")
        [
          "#{indent(level)}InstanceMethodCall(",
          "#{indent(level+1)}object: #{@object.pretty_print(0)}",
          "#{indent(level+1)}method: #{@method_name}",
          "#{indent(level+1)}arguments: [",
          args_str,
          "#{indent(level+1)}]",
          "#{indent(level)})"
        ].join("\n")
      end
    end


    # fn(params) { body }
    class LambdaExpr < Expr
      attr_reader :params, :body_statement, :line

      def initialize(params, body_statement, line)
        @params = params
        @body_statement = body_statement
        @line = line
        # Cache: implicit return for single-expression bodies
        @_implicit = (body_statement.stmts.size == 1 &&
                      body_statement.stmts[0].is_a?(ExpressionStmt))
      end

      def name
        '<fn>'
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

    # fn(x) { x }(5) — IIFE or calling expression that evaluates to function
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
