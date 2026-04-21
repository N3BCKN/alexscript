# frozen_string_literal: true

module AlexScript
  module AST
    # "funkcja" <name> "(" <params>? ")" "{" <body_stmts> "}"
    class FuncDclr < Dclr
      attr_reader :name, :params, :body_statement, :line, :async

      def initialize(name, params, body_statement, line, async: false)
        validate_types([name], [String])
        validate_types(params, [Param]) unless params.nil?
        validate_types([body_statement], Stmts)

        @name = name
        @params = params
        @body_statement = body_statement
        @line = line
        @async = async
        @private = false
      end

      def evaluate(_interpreter, env)
        # store entire parsed 'body' of the function with its current env
        env.set_func(@name, [self, env])
      end

      def set_private(is_private)
        @private = is_private
      end

      def private?
        @private
      end

      def pretty_print(level = 0)
        function_string = []
        function_string << "#{indent(level)}FunctionDeclaration(#{@async ? 'async ' : ''}#{@private ? 'private ' : ''}"
        function_string << "#{indent(level)} name: #{@name}"

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
        validate_types(arguments, Expr) unless arguments.empty?
        @name = name
        @arguments = arguments
        @line = line
      end

      def evaluate(interpreter, env)
        interpreter.evaluate_func_call(self, env)
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

      def evaluate(interpreter, env)
        interpreter.interpret!(@expression, env)
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

      def evaluate(interpreter, env)
        raise Utils::ReturnError.new(interpreter.interpret!(@value, env))
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

      def evaluate(interpreter, env)
        # evaluate object
        obj_type, obj_value = interpreter.interpret!(@object, env)
        Utils.runtime_error("Próba wywołania metody na obiekcie, który nie jest instancją", @line) unless obj_type == :type_instance

        # get class definition
        class_def = obj_value[:class_def]

        # get method
        method_def = class_def[:methods][@method_name]
        Utils.runtime_error("Nieznana metoda #{@method_name}", @line) unless method_def

        # check if method is private
        if method_def[:private]
          # check if we're in context of same instance
          current_instance = env.get_instance
          unless current_instance && current_instance.equal?(obj_value)
            Utils.runtime_error("Próba wywołania prywatnej metody #{@method_name}", @line)
          end
        end

        # evaluate arguments
        arg_values = @arguments.map { |arg| interpreter.interpret!(arg, env) }

        # create environment for method
        method_env = method_def[:env].new_env
        method_env.set_instance(obj_value)  # set current instance

        # assign arguments to parameters
        method_def[:declaration].params.zip(arg_values).each do |param, arg|
          method_env.set_var(param.name, arg[1], arg[0])
        end

        # execute method body
        begin
          Utils::ContextTracker.track_method_call(@method_name) do
            interpreter.interpret!(method_def[:declaration].body, method_env)
          end
          [:type_null, Utils::NULL_VALUE]  # default return value
        rescue Utils::ReturnError => e
          e.value
        end
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
  end
end