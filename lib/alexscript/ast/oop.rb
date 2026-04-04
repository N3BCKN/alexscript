module AlexScript
  module AST
    # klasa <nazwa_klasy> < <klasa_bazowa> { ... }
    class ClassDefinition < Dclr
      attr_reader :name, :parent_class, :body, :line, :is_abstract

      def initialize(name, parent_class, body, line, is_abstract = false)
        validate_types([name], String)
        validate_types([body], Stmts)
        validate_types([parent_class], String) unless parent_class.nil?

        @name = name
        @parent_class = parent_class
        @body = body
        @line = line
        @is_abstract = is_abstract
      end

      def pretty_print(level = 0)
        abstract_str = @is_abstract ? "abstrakcyjna " : ""
        inheritance = @parent_class ? " < #{@parent_class}" : ""
        [
          "#{indent(level)}#{abstract_str}ClassDefinition(#{@name}#{inheritance}",
          @body.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # Wywołanie metody z klasy nadrzędnej: super.metoda(args) lub super(args)
    class SuperMethodCall < Expr
      attr_reader :method_name, :arguments, :line

      def initialize(method_name, arguments, line)
        @method_name = method_name  # nil oznacza konstruktor
        @arguments = arguments || []
        @line = line
      end

      def pretty_print(level = 0)
        args_str = @arguments.map { |arg| arg.pretty_print(level + 1) }.join("\n")
        method_str = @method_name || "konstruktor"
        [
          "#{indent(level)}SuperMethodCall(#{method_str}",
          args_str,
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # Tworzenie instancji klasy: MojaKlasa.nowy(args)
    class ClassInstantiation < Expr
      attr_reader :class_name, :arguments, :line

      def initialize(class_name, arguments, line)
        validate_types([class_name], String)
        @class_name = class_name
        @arguments = arguments || []
        @line = line
      end

      def pretty_print(level = 0)
        args_str = @arguments.map { |arg| arg.pretty_print(level + 1) }.join("\n")
        [
          "#{indent(level)}ClassInstantiation(#{@class_name}",
          args_str,
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # Zmienne instancji @nazwa
    class InstanceVariable < Expr
      attr_reader :name, :line

      def initialize(name, line)
        @name = name
        @line = line
      end

      def pretty_print(level = 0)
        "#{indent(level)}InstanceVariable(#{@name})"
      end
    end

    # Odwołanie do samej instancji: sam
    class SelfReference < Expr
      attr_reader :line

      def initialize(line)
        @line = line
      end

      def pretty_print(level = 0)
        "#{indent(level)}SelfReference(sam)"
      end
    end

    # Przypisanie do zmiennej instancji: @nazwa = wartość
    class InstanceVariableAssignment < Stmt
      attr_reader :name, :value, :line

      def initialize(name, value, line)
        @name = name
        @value = value
        @line = line
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}InstanceVariableAssignment(#{@name}",
          @value.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # Deklaracja zmiennej instancji: niech @nazwa = wartość
    class InstanceVariableDeclaration < Stmt
      attr_reader :name, :value, :line

      def initialize(name, value, line)
        @name = name
        @value = value
        @line = line
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}InstanceVariableDeclaration(#{@name}",
          @value.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # Sekcja prywatnych metod
    class PrivateSection < Stmt
      attr_reader :line

      def initialize(line)
        @line = line
      end

      def pretty_print(level = 0)
        "#{indent(level)}PrivateSection()"
      end
    end
		
		# Statyczna zmienna klasowa
    class StaticVariable < Expr
      attr_reader :class_name, :name, :line

      def initialize(class_name, name, line)
        @class_name = class_name
        @name = name
        @line = line
      end

      def pretty_print(level = 0)
        "#{indent(level)}StaticVariable(#{@class_name}.#{@name})"
      end
    end

		class StaticVariableDeclaration < Stmt
      attr_reader :class_name, :name, :value, :line

      def initialize(class_name, name, value, line)
        @class_name = class_name
        @name = name
        @value = value
        @line = line
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}StaticVariableDeclaration(#{@class_name}.#{@name}",
          @value.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end
    end

		class StaticKeyword < Stmt
			attr_reader :line
	
			def initialize(line)
				@line = line
			end
	
			def pretty_print(level = 0)
				"#{indent(level)}StaticKeyword()"
			end
		end

    # Wywołanie statycznej metody klasy: KlasaNazwa.metoda_statyczna()
    class StaticMethodCall < Expr
      attr_reader :class_name, :method_name, :arguments, :line

      def initialize(class_name, method_name, arguments, line)
        @class_name = class_name
        @method_name = method_name
        @arguments = arguments || []
        @line = line
      end

      def pretty_print(level = 0)
        args_str = @arguments.map { |arg| arg.pretty_print(level + 1) }.join("\n")
        [
          "#{indent(level)}StaticMethodCall(#{@class_name}.#{@method_name}",
          args_str,
          "#{indent(level)})"
        ].join("\n")
      end
    end
  end
end