# frozen_string_literal: true

module AlexScript
  module AST
    class Identifier < Expr
      attr_reader :name, :line

      def initialize(name, line)
        @name = name
        @line = line
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

      def pretty_print(level = 0)
        [
          "#{indent(level)}InstanceVariableDeclaration(@#{@name}",
          @value.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end
    end
  end
end
