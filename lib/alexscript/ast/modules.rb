# frozen_string_literal: true

module AlexScript
  module AST

    # modul Nazwa { ... }
    class ModuleDefinition < Dclr
      attr_reader :name, :body, :line, :parent_module

      def initialize(name, body, line, parent_module = nil)
        validate_types([name], String)
        validate_types([body], Stmts)
        
        @name = name
        @body = body
        @line = line
        @parent_module = parent_module
      end

      def pretty_print(level = 0)
        parent_str = @parent_module ? " (w #{@parent_module})" : ""
        [
          "#{indent(level)}ModuleDefinition(#{@name}#{parent_str}",
          @body.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # Modul::Klasa, Modul::funkcja()
    class ModuleAccess < Expr
      attr_reader :module_path, :member_name, :line

      def initialize(module_path, member_name, line)
        validate_types([module_path], Array)
        validate_types([member_name], String)
        
        @module_path = module_path  # ["Modul1", "Modul2"]
        @member_name = member_name
        @line = line
      end

      def pretty_print(level = 0)
        path_str = @module_path.join("::")
        "#{indent(level)}ModuleAccess(#{path_str}::#{@member_name})"
      end
    end

    # Modul::Klasa.nowy()
    class ModuleClassInstantiation < Expr
      attr_reader :module_path, :class_name, :arguments, :line

      def initialize(module_path, class_name, arguments, line)
        validate_types([module_path], Array)
        validate_types([class_name], String)
        
        @module_path = module_path
        @class_name = class_name
        @arguments = arguments || []
        @line = line
      end

      def pretty_print(level = 0)
        path_str = @module_path.join("::")
        args_str = @arguments.map { |arg| arg.pretty_print(level + 1) }.join("\n")
        [
          "#{indent(level)}ModuleClassInstantiation(#{path_str}::#{@class_name}",
          args_str,
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # Modul::funkcja(args)
    class ModuleFunctionCall < Expr
      attr_reader :module_path, :function_name, :arguments, :line

      def initialize(module_path, function_name, arguments, line)
        validate_types([module_path], Array)
        validate_types([function_name], String)
        
        @module_path = module_path
        @function_name = function_name
        @arguments = arguments || []
        @line = line
      end

      def pretty_print(level = 0)
        path_str = @module_path.join("::")
        args_str = @arguments.map { |arg| arg.pretty_print(level + 1) }.join("\n")
        [
          "#{indent(level)}ModuleFunctionCall(#{path_str}::#{@function_name}",
          args_str,
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # dolacz ModuleName
    class IncludeModule < Stmt
      attr_reader :module_name, :line

      def initialize(module_name, line)
        validate_types([module_name], String)
        @module_name = module_name
        @line = line
      end

      def pretty_print(level = 0)
        "#{indent(level)}IncludeModule(#{@module_name})"
      end
    end
  end
end