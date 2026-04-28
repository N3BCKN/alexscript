# frozen_string_literal: true

module AlexScript
  module AST
    class Identifier < Expr
      attr_reader :name, :line

      def initialize(name, line)
        @name = name
        @line = line
      end

      def evaluate(_interpreter, env)
        # check if it's a variable
        var_raw = env.get_var(@name)

        if var_raw.nil?
          # if not a var, check if it's a function call
          func = env.get_func(@name)
          return [:type_function, { declaration: func[0], env: func[1] }] if func

          # if not a function, check if it's a module (modules are first-class values)
          mod = env.get_module(@name)
          return [:type_module, mod] if mod

          # if not a module, check if it's a class (classes are first-class values too)
          klass = env.get_class(@name)
          if klass
            # add :name for introspection (mirrors what evaluate_method_call does)
            klass[:name] ||= @name
            return [:type_class, klass]
          end

          Utils.runtime_error("Niezadeklarowany identyfikator #{@name}", @line)
        end

        Utils.runtime_error("Niezainicjowany identyfikator #{@name}", @line) if var_raw[:type].nil?
        [var_raw[:type], var_raw[:value]]
      end

      def pretty_print(level = 0)
        "#{indent(level)}Identifier(#{@name})"
      end
    end

    # Example: x = 42, assign value the variables
    class Assignment < Stmt
      attr_reader :left, :right, :line

      def initialize(left, right, line)
        validate_types([left, right], [Expr])
        @left = left
        @right = right
        @line = line
      end

      def evaluate(interpreter, env)
        var = env.get_var(@left.name)
        if var.nil?
          Utils.runtime_error("Zmienna #{@left.name} musi byc zadeklarowana z 'niech' przed przypisaniem", @line)
        elsif var[:constant]
          Utils.runtime_error("Zmienna #{@left.name} jest stala i nie moze byc zmieniana", @line)
        end

        # evaluate right side of the expression
        right_type, right_value = interpreter.interpret!(@right, env)
        # assign new value or overwrite existing one
        env.set_var(@left.name, right_value, right_type)
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

    class AssignmentExpr < Expr
      attr_reader :left, :right, :line

      def initialize(left, right, line)
        validate_types([left], [Identifier], 'left')
        validate_types([right], [Expr], 'right')
        @left = left
        @right = right
        @line = line
      end

      def evaluate(interpreter, env)
        var = env.get_var(@left.name)
        if var.nil?
          Utils.runtime_error("Zmienna #{@left.name} musi byc zadeklarowana z 'niech' przed przypisaniem", @line)
        elsif var[:constant]
          Utils.runtime_error("Zmienna #{@left.name} jest stala i nie moze byc zmieniana", @line)
        end

        # evaluate right side of the expression
        right_type, right_value = interpreter.interpret!(@right, env)
        # assign new value and overwrite existing one
        env.set_var(@left.name, right_value, right_type)
        [right_type, right_value]
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}AssignmentExpr(",
          @left.pretty_print(level + 1),
          @right.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # eg  globalna niech x = 5, global variable
    class VariableDeclaration < Stmt
      attr_reader :left, :right, :line

      def initialize(left, right, line)
        validate_types([left, right], [Expr])
        @left = left
        @right = right
        @line = line
      end

      def evaluate(interpreter, env)
        right_type, right_value = interpreter.interpret!(@right, env)
        # declare new variable
        var_name = @left.name
        is_constant = var_name.match?(/^[A-Z_]+$/) # declare as constant if CAPITALIZED

        env.set_local_var(var_name, right_value, right_type, is_constant)
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}VariableDeclaration(",
          @left.pretty_print(level + 1),
          @right.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # eg  globalna niech x = 5
    class GlobalVariableDeclaration < Stmt
      attr_reader :left, :right, :line

      def initialize(left, right, line)
        validate_types([left, right], [Expr])
        @left = left
        @right = right
        @line = line
      end

      def evaluate(interpreter, env)
        global_env = env.get_global_env

        right_type, right_value = interpreter.interpret!(@right, env)

        # declare new variable in global scope
        global_env.set_local_var(@left.name, right_value, right_type)
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}GlobalVariableDeclaration(",
          @left.pretty_print(level + 1),
          @right.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end
    end

    #eg niech @x = 5
    class InstanceVariable < Expr
      attr_reader :name, :line

      def initialize(name, line)
        validate_types([name], [String])
        @name = name
        @line = line
      end

      def evaluate(_interpreter, env)
        instance = env.get_instance
        Utils.runtime_error("Nie można użyć zmiennej instancji poza kontekstem instancji", @line) unless instance

        # get instance variable value
        value = instance[:instance_vars][@name]
        if value.nil?
          [:type_null, Utils::NULL_VALUE]  # uninitialized instance variable returns 'nic'
        else
          value
        end
      end

      def pretty_print(level = 0)
        "#{indent(level)}InstanceVariable(@#{@name})"
      end
    end

    class InstanceVariableAssignment < Stmt
      attr_reader :name, :value, :line

      def initialize(name, value, line)
        validate_types([name], [String])
        validate_types([value], [Expr])
        @name = name
        @value = value
        @line = line
      end

      def evaluate(interpreter, env)
        instance = env.get_instance
        Utils.runtime_error("Nie można przypisać zmiennej instancji poza kontekstem instancji", @line) unless instance

        # evaluate value to assign
        value_type, value_value = interpreter.interpret!(@value, env)

        # assign value to instance variable
        instance[:instance_vars][@name] = [value_type, value_value]

        [value_type, value_value]
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}InstanceVariableAssignment(@#{@name}",
          @value.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end
    end


    class InstanceVariableDeclaration < Stmt
      attr_reader :name, :value, :line

      def initialize(name, value, line)
        validate_types([name], [String])
        validate_types([value], [Expr])
        @name = name
        @value = value
        @line = line
      end

      def evaluate(interpreter, env)
        instance = env.get_instance
        Utils.runtime_error("Nie można zadeklarować zmiennej instancji poza kontekstem instancji", @line) unless instance

        # evaluate value
        value_type, value_value = interpreter.interpret!(@value, env)

        # save instance variable
        instance[:instance_vars][@name] = [value_type, value_value]

        [value_type, value_value]
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}InstanceVariableDeclaration(@#{@name}",
          @value.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end
    end

    class InstanceVariableCompoundAssignment < Stmt
      attr_reader :name, :operator, :right, :line

      def initialize(name, operator, right, line)
        validate_types([name], [String])
        validate_types([operator], [Utils::Token], 'operator')
        validate_types([right], [Expr], 'right')
        @name = name
        @operator = operator
        @right = right
        @line = line
      end

      def evaluate(interpreter, env)
        instance = env.get_instance
        Utils.runtime_error("Nie można użyć zmiennej instancji poza kontekstem instancji", @line) unless instance

        current = instance[:instance_vars][@name]
        Utils.runtime_error("Niezdefiniowana zmienna instancji @#{@name}", @line) unless current
        current_type, current_value = current

        _, right_value = interpreter.interpret!(@right, env)

        new_value = case @operator.token_type
                    when :tok_pluseq
                      current_value + right_value
                    when :tok_minuseq
                      current_value - right_value
                    when :tok_stareq
                      current_value * right_value
                    when :tok_slasheq
                      Utils.runtime_error('Dzielenie przez zero', @line) if right_value == 0
                      current_value / right_value
                    end

        instance[:instance_vars][@name] = [current_type, new_value]
      end

      def pretty_print(level = 0)
        ["#{indent(level)}InstanceVariableCompoundAssignment(@#{@name}",
         "#{indent(level + 1)}operator: #{@operator.lexeme}",
         @right.pretty_print(level + 1),
         "#{indent(level)})"].join("\n")
      end
    end
  end
end