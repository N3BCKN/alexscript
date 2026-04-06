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
        validate_types([pairs], [Hash], 'object')
        @pairs = pairs
        @line = line
      end

      def pretty_print(level = 0)
        pairs_str = @pairs.map do |k, v|
          "#{indent(level + 1)}#{k}: #{v.pretty_print(level + 1)}"
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
        # can be identifier or other ObjectOrArrayAccess
        #
        # unless array.is_a?(Identifier) || array.is_a?(ObjectOrArrayAccess)
        #   raise TypeError, "Invalid array/object: Expected Identifier or ObjectOrArrayAccess, got #{array.class}"
        # end
        validate_types([array], [Identifier, ObjectOrArrayAccess, InstanceVariable], 'index')
        validate_types([index], [Expr], 'index')
        @array = array
        @index = index
        @line = line
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
        # can be identifier or other ObjectOrArrayAssignment
        validate_types([array], [Identifier, ObjectOrArrayAccess, InstanceVariable], 'index')
        validate_types([index], [Expr], 'index')
        validate_types([value], [Expr], 'value')
        @array = array
        @index = index
        @value = value
        @line = line
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
