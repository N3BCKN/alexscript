# frozen_string_literal: true

module AlexScript
  module AST
    # example: niech tablica = [1,'dwa', 3, prawda]
    class ArrayLiteral < Expr
      attr_reader :elements, :line

      def initialize(elements, line)
        validate_types(elements, [Expr], 'array elements')
        @elements = elements
        @line = line
      end

      def evaluate(interpreter, env)
        elements = []

        # interpret each element of the array
        @elements.each do |element|
          element_type, element_value = interpreter.interpret!(element, env)
          elements << {
            type: element_type,
            value: element_value
          }
        end

        [:type_array, elements]
      end

      def pretty_print(level = 0)
        elements_string = @elements.map { |elem| elem.pretty_print(level + 1) }.join("\n")
        [
          "#{indent(level)}Array(",
          elements_string,
          "#{indent(level)})"
        ].join("\n")
      end
    end

    class ArrayAccessStmt < Stmt
      attr_reader :expression, :line

      def initialize(expression, line)
        validate_types([expression], [ArrayAccess])
        @expression = expression
        @line = line
      end

      def evaluate(interpreter, env)
        interpreter.interpret!(@expression, env)
      end

      def pretty_print(level = 0)
        ["#{indent(level)}ArrayAccessStmt(",
         @expression.pretty_print(level + 1),
         "#{indent(level)})"].join("\n")
      end
    end

    class ObjectOrArrayAccessStmt < Stmt
      attr_reader :expression, :line

      def initialize(expression, line)
        validate_types([expression], [ObjectOrArrayAccess])
        @expression = expression
        @line = line
      end

      def evaluate(interpreter, env)
        interpreter.interpret!(@expression, env)
      end

      def pretty_print(level = 0)
        ["#{indent(level)}ObjectOrArrayAccessStmt(",
         @expression.pretty_print(level + 1),
         "#{indent(level)})"].join("\n")
      end
    end

    # eg niech obiekt = {para: "klucz"}
    class ObjectLiteral < Expr
      attr_reader :pairs, :line

      def initialize(pairs, line)
        validate_types([pairs], [Array], 'object')
        @pairs = pairs
        @line = line
      end

      def evaluate(interpreter, env)
        pairs = {}
        @pairs.each do |key_expr, value_expr|
          _key_type, key_value = interpreter.interpret!(key_expr, env)
          key = Utils.object_key(key_value, @line)
          value_type, value = interpreter.interpret!(value_expr, env)
          pairs[key] = { type: value_type, value: value }
        end
        [:type_object, pairs]
      end

      def pretty_print(level = 0)
        pairs_str = @pairs.map do |k, v|
          "#{indent(level + 1)}#{k.pretty_print(0)}: #{v.pretty_print(level + 1)}"
        end.join("\n")

        [
          "#{indent(level)}Object(",
          pairs_str,
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # I've decided to put both arrays and objects into the very same AST model
    # since it was hard for parser to figure out which one was called with an identifier (var) as a key/index
    # (niech x = "5", array[x], obiekt[x])
    # especially since parser should not get access to the resources from env, to figure it out in this case
    # now it's a interpreter job to distinguish them
    class ObjectOrArrayAccess < Expr
      attr_reader :array, :index, :line

      def initialize(array, index, line)
        validate_types([array], [Identifier, ObjectOrArrayAccess, InstanceVariable, MethodCall, FuncCall, StaticMethodCall, ModuleFunctionCall], 'index')
        validate_types([index], [Expr], 'index')
        @array = array
        @index = index
        @line = line
      end

      def evaluate(interpreter, env)
        if @array.is_a?(AST::Identifier)
          object_var = env.get_var(@array.name)
        else
          type, value = interpreter.interpret!(@array, env)
          object_var = { type: type, value: value }
        end

        key_type, key_value = interpreter.interpret!(@index, env)

        case object_var[:type]
        when :type_array
          Utils.runtime_error('Indeks tablicy musi byc liczbą całkowitą', @line) unless key_type == :type_int
          length = object_var[:value].length
          Utils.runtime_error('Indeks poza zakresem', @line) if key_value >= length || key_value < -length

          element = object_var[:value][key_value]
          [element[:type], element[:value]]
        when :type_object
          key = Utils.object_key(key_value, @line)
          value = object_var[:value][key]
          if value
            [value[:type], value[:value]]
          else
            [:type_null, Utils::NULL_VALUE]
          end
        when :type_string
          Utils.runtime_error('Indeks napisu musi byc liczbą całkowitą', @line) unless key_type == :type_int
          str = object_var[:value]
          length = str.length
          Utils.runtime_error('Indeks poza zakresem', @line) if key_value >= length || key_value < -length

          [:type_string, -str[key_value]]
        else
          Utils.runtime_error("Wyrazenie #{interpreter.get_access_path(self, env)} nie jest ani tablica ani obiektem", @line)
        end
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}ObjectOrArrayAccess(",
          "#{indent(level + 1)}array/object: #{@array.pretty_print(level + 1)}",
          "#{indent(level + 1)}index/key: #{@index.pretty_print(level + 1)}",
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # same story as above, obiekt[x] = 5 and array[x] = 5 were confusing parser as a separate ast object
    class ObjectOrArrayAssignment < Expr
      attr_reader :array, :index, :value, :line

      def initialize(array, index, value, line)
        validate_types([array], [Identifier, ObjectOrArrayAccess, InstanceVariable, MethodCall, FuncCall], 'index')
        validate_types([index], [Expr], 'index')
        validate_types([value], [Expr], 'value')
        @array = array
        @index = index
        @value = value
        @line = line
      end

      def evaluate(interpreter, env)
        if @array.is_a?(AST::Identifier)
          object_var = env.get_var(@array.name)
          Utils.runtime_error("Niezdefiniowana zmienna #{interpreter.get_access_path(self, env)}", @line) unless object_var
        else
          type, value = interpreter.interpret!(@array, env)
          object_var = { type: type, value: value }
        end

        key_type, key_value = interpreter.interpret!(@index, env)
        value_type, value = interpreter.interpret!(@value, env)

        case object_var[:type]
        when :type_array
          Utils.runtime_error('Indeks tablicy musi byc liczbą całkowitą', @line) unless key_type == :type_int
          length = object_var[:value].length
          Utils.runtime_error('Indeks poza zakresem', @line) if key_value >= length || key_value < -length

          object_var[:value][key_value] = { type: value_type, value: value }
        when :type_object
          key = Utils.object_key(key_value, @line)
          object_var[:value][key] = { type: value_type, value: value }
        when :type_string
          Utils.runtime_error('Napisy sa niemutowalne — nie mozna przypisac znaku przez indeks', @line)
        else
          Utils.runtime_error("Wyrazenie #{interpreter.get_access_path(self, env)} nie jest ani tablica ani obiektem", @line)
        end

        # update var in env for a direct access only
        env.set_var(@array.name, object_var[:value], object_var[:type]) if @array.is_a?(AST::Identifier)

        [value_type, value]
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}ObjectOrArrayAssignment(",
          "#{indent(level + 1)}array/object: #{@array.pretty_print(level + 1)}",
          "#{indent(level + 1)}index/key: #{@index.pretty_print(level + 1)}",
          "#{indent(level + 1)}value: #{@value.pretty_print(level + 1)}",
          "#{indent(level)})"
        ].join("\n")
      end
    end
  end
end