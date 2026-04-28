# frozen_string_literal: true

module AlexScript
  module AST
    # klasa <klasa> < <klasa_bazowa> { ... }
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

      def evaluate(interpreter, env)
        # new environment for class
        class_env = env.new_env

        # class definition
        class_def = {
          parent: @parent_class,
          body: @body,
          methods: {},
          static_methods: {},
          static_vars: {},
          is_abstract: @is_abstract,
          included_modules: []
        }

        # iterate through statements in class body
        in_private_section = false
        in_static_section = false

        @body.stmts.each do |stmt|
          if stmt.is_a?(AST::PrivateSection)
            in_private_section = true
            next
          end

          if stmt.is_a?(AST::StaticKeyword)
            in_static_section = true
            next
          end

          # handle include module (dolacz)
          if stmt.is_a?(AST::IncludeModule)
            module_def = env.get_module(stmt.module_name)

            unless module_def
              Utils.runtime_error("Nie znaleziono modułu #{stmt.module_name}", stmt.line)
            end

            # fetch constants from module
            if module_def[:constants]
              module_def[:constants].each do |const_name, const_data|
                class_env.set_local_var(const_name, const_data[:value], const_data[:type], true)
              end
            end

            # add module functions as a class methods
            if module_def[:functions]
              module_def[:functions].each do |func_name, func_data|
                func_declr, _module_env = func_data

                # skip if method already exist
                next if class_def[:methods].key?(func_name)

                class_def[:methods][func_name] = {
                  declaration: func_declr,
                  env: class_env,
                  private: false
                }
              end
            end

            class_def[:included_modules] << stmt.module_name
            next
          end

          if stmt.is_a?(AST::FuncDclr)
            if in_static_section
              # static method
              class_def[:static_methods][stmt.name] = {
                declaration: stmt,
                env: class_env,
                private: in_private_section
              }
              in_static_section = false  # reset flag
            else
              # normal instance method
              class_def[:methods][stmt.name] = {
                declaration: stmt,
                env: class_env,
                private: in_private_section
              }
            end
          end

          # handle static variables
          if stmt.is_a?(AST::VariableDeclaration) && in_static_section
            value_type, value_value = interpreter.interpret!(stmt.right, class_env)
            class_def[:static_vars][stmt.left.name] = { type: value_type, value: value_value }
            in_static_section = false  # reset flag
          end
        end

        class_def[:class_env] = class_env

        # save class definition in environment
        env.define_class(@name, class_def)

        [:type_null, Utils::NULL_VALUE]
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

      def evaluate(interpreter, env)
        # check if we're in instance context
        instance = env.get_instance
        Utils.runtime_error("Nie można użyć 'super' poza kontekstem instancji", @line) unless instance

        # determine method name
        current_method_name = nil

        if @method_name.nil?
          # 1. most important change: always try to read current method context
          current_method_name = Utils::ContextTracker.current_method_name

          # 2. if context is unknown, check if we're in constructor
          if current_method_name.nil?
            # check if super() call is in first line of constructor
            # by analyzing instance variables count and statement type in method body
            if instance[:instance_vars].size <= 1
              current_method_name = "konstruktor"
            else
              # if we can't determine context, block execution
              Utils.runtime_error("Nie można określić kontekstu metody dla wywołania 'super()'", @line)
            end
          end
        else
          # use explicitly provided method name
          current_method_name = @method_name
        end

        # find method in parent class
        method_result = env.find_parent_method(instance, current_method_name)

        # super() for native parent constructor
        if method_result.nil? && current_method_name == "konstruktor"
          parent_name = instance[:class_def][:parent]
          if parent_name
            parent_def = env.get_class(parent_name)
            if parent_def && parent_def[:native] && parent_def[:native_constructor]
              arguments = @arguments.map { |arg| interpreter.interpret!(arg, env) }
              begin
                native_obj = Utils::NativeClassRegistry.dispatch_constructor(parent_name, arguments)
                instance[:__native__] = native_obj
              rescue => e
                Utils.runtime_error("Błąd konstruktora natywnego: #{e.message}", @line)
              end
              return [:type_null, Utils::NULL_VALUE]
            end
          end
        end

        Utils.runtime_error("Nie znaleziono metody #{current_method_name} w klasie nadrzędnej", @line) unless method_result

        method_info = method_result[:method_info]

        # Native super dispatch ──
        if method_info[:native_lambda]
          arguments = @arguments.map { |arg| interpreter.interpret!(arg, env) }

          # For constructor super(), create native object and attach to instance
          if current_method_name == "konstruktor"
            parent_class_name = method_result[:class_name]
            begin
              native_obj = Utils::NativeClassRegistry.dispatch_constructor(parent_class_name, arguments)
              instance[:__native__] = native_obj
            rescue => e
              Utils.runtime_error("Błąd konstruktora natywnego: #{e.message}", @line)
            end
            return [:type_null, Utils::NULL_VALUE]
          end

          # For regular method super(), dispatch native lambda
          native_obj = instance[:__native__]
          unless native_obj
            Utils.runtime_error(
              "Brak obiektu natywnego — upewnij się, że konstruktor wywołuje super()",
              @line
            )
          end

          begin
            result = Utils::NativeClassRegistry.dispatch_native_lambda(
              method_info[:native_lambda], native_obj, arguments
            )
          rescue => e
            Utils.runtime_error("Błąd metody #{current_method_name}: #{e.message}", @line)
          end

          return result
        end

        # evaluate arguments
        arguments = @arguments.map { |arg| interpreter.interpret!(arg, env) }

        # check argument count
        params = method_info[:declaration].params

        # handle rest type parameters
        rest_param = params.find(&:rest?)
        min_args = params.count { |p| !p.has_default? && !p.rest? }
        max_args = rest_param ? Float::INFINITY : params.size

        if arguments.size < min_args
          Utils.runtime_error(
            "Metoda #{current_method_name} oczekiwała, a minimum #{min_args} argumentów, otrzymała #{arguments.size}",
            @line
          )
        end

        unless rest_param
          if arguments.size > max_args
            Utils.runtime_error(
              "Metoda #{current_method_name} oczekiwała, a maksymalnie #{max_args} argumentów, otrzymała #{arguments.size}",
              @line
            )
          end
        end

        # create new environment for method
        method_env = method_info[:env].new_env
        method_env.set_instance(instance)  # use current instance

        # assign arguments to parameters
        rest_idx = params.index(&:rest?)
        rest_position = rest_idx || params.size

        normal_params = params.reject(&:rest?)
        normal_params.each_with_index do |param, idx|
          if idx < arguments.size && (rest_idx.nil? || idx < rest_idx)
            method_env.set_local_var(param.name, arguments[idx][1], arguments[idx][0])
          elsif param.has_default?
            default_value = interpreter.interpret!(param.default_value, method_info[:env])
            method_env.set_local_var(param.name, default_value[1], default_value[0])
          else
            Utils.runtime_error("Brakujący argument #{param.name}", @line)
          end
        end

        # handle rest parameter
        if rest_param
          rest_args = arguments[rest_position..-1] || []
          rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
          method_env.set_local_var(rest_param.name, rest_array_elements, :type_array)
        end

        # execute method body
        begin
          # keep current method context so nested super calls work correctly
          Utils::ContextTracker.track_method_call(current_method_name) do
            interpreter.interpret!(method_info[:declaration].body_statement, method_env)
          end
          result = [:type_null, Utils::NULL_VALUE]  # by default return 'nic'
        rescue Utils::ReturnError => e
          result = e.value  # or specific value returned by method
        end

        result
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

      def evaluate(interpreter, env)
        # get class definition
        class_def = env.get_class(@class_name)
        Utils.runtime_error("Nieznana klasa #{@class_name}", @line) unless class_def

        # check if class is not abstract
        Utils.runtime_error("Nie można utworzyć instancji klasy abstrakcyjnej #{@class_name}", @line) if class_def[:is_abstract]

        # Native class constructor
        if class_def[:native]
          arguments = @arguments.map { |arg| interpreter.interpret!(arg, env) }

          begin
            native_obj = Utils::NativeClassRegistry.dispatch_constructor(@class_name, arguments)
          rescue => e
            Utils.runtime_error("Błąd konstruktora natywnego #{@class_name}: #{e.message}", @line)
          end

          instance = {
            class_name: @class_name,
            instance_vars: {},
            class_def: class_def,
            __native__: native_obj
          }

          return [:type_instance, instance]
        end

        # create new instance
        instance = {
          class_name: @class_name,
          instance_vars: {},  # instance variables
          class_def: class_def  # reference to class definition
        }

        # prepare constructor arguments
        arguments = @arguments.map do |arg|
          interpreter.interpret!(arg, env)
        end

        # call constructor if exists
        constructor = class_def[:methods]["konstruktor"]
        if constructor
          # create environment for constructor
          constructor_env = constructor[:env].new_env
          constructor_env.set_instance(instance)

          # check argument count
          params = constructor[:declaration].params

          # handle rest type parameters
          rest_param = params.find(&:rest?)
          min_args = params.count { |p| !p.has_default? && !p.rest? }
          max_args = rest_param ? Float::INFINITY : params.size

          if arguments.size < min_args
            Utils.runtime_error(
              "Konstruktor klasy #{@class_name} oczekiwał minimum #{min_args} argumentów, otrzymała #{arguments.size}",
              @line
            )
          end

          unless rest_param
            if arguments.size > max_args
              Utils.runtime_error(
                "Konstruktor klasy #{@class_name} oczekiwała maksymalnie #{max_args} argumentów, otrzymała #{arguments.size}",
                @line
              )
            end
          end

          # assign arguments to parameters
          rest_idx = params.index(&:rest?)
          rest_position = rest_idx || params.size

          normal_params = params.reject(&:rest?)
          normal_params.each_with_index do |param, idx|
            if idx < arguments.size && (rest_idx.nil? || idx < rest_idx)
              constructor_env.set_local_var(param.name, arguments[idx][1], arguments[idx][0])
            elsif param.has_default?
              default_value = interpreter.interpret!(param.default_value, constructor[:env])
              constructor_env.set_local_var(param.name, default_value[1], default_value[0])
            else
              Utils.runtime_error("Brakujący argument #{param.name}", @line)
            end
          end

          # handle rest parameter
          if rest_param
            rest_args = arguments[rest_position..-1] || []
            rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
            constructor_env.set_local_var(rest_param.name, rest_array_elements, :type_array)
          end

          # execute constructor
          Utils::ContextTracker.current_class_name = @class_name
          Utils::CallStackTracker.push(:constructor, @class_name, interpreter.current_file, @line)
          begin
            Utils::ContextTracker.track_method_call("konstruktor") do
              interpreter.interpret!(constructor[:declaration].body_statement, constructor_env)
            end
          rescue Utils::ReturnError
            # ignore return value from constructor
          ensure
            Utils::CallStackTracker.pop
          end
        elsif !constructor
          # No constructor in current class — check if parent has a native constructor
          parent_name = class_def[:parent]
          if parent_name
            parent_def = env.get_class(parent_name)
            if parent_def && parent_def[:native]
              arguments = @arguments.map { |arg| interpreter.interpret!(arg, env) } if arguments.nil? || arguments.empty?
              begin
                native_obj = Utils::NativeClassRegistry.dispatch_constructor(parent_name, arguments || [])
                instance[:__native__] = native_obj
              rescue => e
                Utils.runtime_error("Błąd konstruktora natywnego #{parent_name}: #{e.message}", @line)
              end
            end
          end
        end

        [:type_instance, instance]
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

    # Odwołanie do samej instancji: sam
    class SelfReference < Expr
      attr_reader :line

      def initialize(line)
        @line = line
      end

      def evaluate(_interpreter, env)
        instance = env.get_instance

        unless instance
          Utils.runtime_error(
            "Nie można użyć 'sam' poza kontekstem instancji klasy. 'sam' może być użyte tylko w metodach instancji i konstruktorze.",
            @line
          )
        end

        [:type_instance, instance]
      end

      def pretty_print(level = 0)
        "#{indent(level)}SelfReference(sam)"
      end
    end

    # Sekcja prywatnych metod
    class PrivateSection < Stmt
      attr_reader :line

      def initialize(line)
        @line = line
      end

      # PrivateSection is a marker consumed structurally by ClassDefinition /
      # ModuleDefinition during their own evaluate — it never reaches dispatch
      # at runtime. Implement evaluate as a no-op just in case.
      def evaluate(_interpreter, _env)
        [:type_null, Utils::NULL_VALUE]
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

      def evaluate(_interpreter, env)
        # get class definition
        class_def = env.get_class(@class_name)
        Utils.runtime_error("Nieznana klasa #{@class_name}", @line) unless class_def

        # look for static variable in whole class hierarchy
        var = nil
        current_class_def = class_def

        while current_class_def && !var
          # check if variable exists in current class
          if current_class_def[:static_vars] && current_class_def[:static_vars][@name]
            var = current_class_def[:static_vars][@name]
            break
          end

          # if not, check base class
          parent_name = current_class_def[:parent]
          break unless parent_name

          current_class_def = env.get_class(parent_name)
        end

        Utils.runtime_error("Nieznana zmienna statyczna '#{@name}' w klasie #{@class_name}", @line) unless var

        [var[:type], var[:value]]
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

      def evaluate(interpreter, env)
        class_name = @class_name
        class_def = env.get_class(class_name)

        # check if class exists
        if class_def.nil?
          Utils.runtime_error("Nie można zdefiniować zmiennej statycznej dla nieistniejącej klasy #{class_name}", @line)
        end

        # check if we're not trying to overwrite existing static variable
        if class_def[:static_vars][@name] && @name.match?(/^[A-Z_]+$/)
          Utils.runtime_error("Statyczna stała #{class_name}.#{@name} została, a już zdefiniowana i nie może być zmieniona", @line)
        end

        value_type, value_value = interpreter.interpret!(@value, env)
        env.set_static_var(@class_name, @name, value_value, value_type)

        [value_type, value_value]
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

      # StaticKeyword is a structural marker, consumed by ClassDefinition /
      # ModuleDefinition during their evaluate. No-op if it ever reaches dispatch.
      def evaluate(_interpreter, _env)
        [:type_null, Utils::NULL_VALUE]
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

      def evaluate(interpreter, env)
        # get class definition
        class_def = env.get_class(@class_name)

        # Fallback: Name is uppercase so parser produced StaticMethodCall,
        # but it might be a module rather than a class.
        # Modules are first-class values — support built-in reflection methods on them.
        unless class_def
          module_def = env.get_module(@class_name)
          if module_def
            if env.built_in_methods.get_method(:type_module, @method_name)
              evaluated_args = @arguments.map { |arg| interpreter.interpret!(arg, env)[1] }
              result = env.call_method(:type_module, @method_name, module_def, evaluated_args)

              # tuple shortcut (method already returned [type, value])
              return result if result.is_a?(Array) && result.size == 2 && result[0].is_a?(Symbol)

              result_type = case result
                            when Integer then :type_int
                            when Float then :type_float
                            when String then :type_string
                            when TrueClass, FalseClass then :type_bool
                            when Array then :type_array
                            when NilClass then :type_null
                            when Hash then :type_object
                            else :type_object
                            end
              return [result_type, result]
            else
              Utils.runtime_error("Nieznana metoda '#{@method_name}' dla modułu #{@class_name}", @line)
            end
          end
        end

        Utils.runtime_error("Nieznana klasa #{@class_name}", @line) unless class_def

        if env.built_in_methods.get_method(:type_class, @method_name)
          # prepare arguments
          evaluated_args = @arguments.map { |arg| interpreter.interpret!(arg, env)[1] }

          # add class name
          class_with_name = class_def.dup
          class_with_name[:name] = @class_name

          # call method
          result = env.call_method(:type_class, @method_name, class_with_name, evaluated_args)

          # return bool type
          if result.is_a?(Array) && result.size == 2 && result[0].is_a?(Symbol)
            return result
          end

          # convert result
          result_type = case result
                        when Integer then :type_int
                        when Float then :type_float
                        when String then :type_string
                        when TrueClass, FalseClass then :type_bool
                        when Array then :type_array
                        when NilClass then :type_null
                        when Hash then :type_object
                        else :type_object
                        end

          return [result_type, result]
        end

        # look for static method in whole class hierarchy
        method_info = nil
        current_class_def = class_def

        while current_class_def && !method_info
          # check if method exists in current class
          if current_class_def[:static_methods] && current_class_def[:static_methods][@method_name]
            method_info = current_class_def[:static_methods][@method_name]
            break
          end

          # if not, check base class
          parent_name = current_class_def[:parent]
          break unless parent_name

          current_class_def = env.get_class(parent_name)
        end

        Utils.runtime_error("Nieznana metoda statyczna '#{@method_name}' w klasie #{@class_name}", @line) unless method_info

        # evaluate arguments
        arguments = @arguments.map { |arg| interpreter.interpret!(arg, env) }

        if method_info[:native_lambda]
          begin
            result = Utils::NativeClassRegistry.dispatch_static_lambda(
              method_info[:native_lambda], arguments
            )
          rescue => e
            Utils.runtime_error("Błąd metody statycznej #{@method_name}: #{e.message}", @line)
          end
          return result
        end

        # check argument count
        params = method_info[:declaration].params

        # handle rest type parameters
        rest_param = params.find(&:rest?)
        min_args = params.count { |p| !p.has_default? && !p.rest? }
        max_args = rest_param ? Float::INFINITY : params.size

        if arguments.size < min_args
          Utils.runtime_error(
            "Metoda statyczna '#{@method_name}' oczekiwała, a minimum #{min_args} argumentów, otrzymała #{arguments.size}",
            @line
          )
        end

        unless rest_param
          if arguments.size > max_args
            Utils.runtime_error(
              "Metoda statyczna '#{@method_name}' oczekiwała, a maksymalnie #{max_args} argumentów, otrzymała #{arguments.size}",
              @line
            )
          end
        end

        # create new environment for static method
        method_env = method_info[:env].new_env

        # assign arguments to parameters
        rest_idx = params.index(&:rest?)
        rest_position = rest_idx || params.size

        normal_params = params.reject(&:rest?)
        normal_params.each_with_index do |param, idx|
          if idx < arguments.size && (rest_idx.nil? || idx < rest_idx)
            method_env.set_local_var(param.name, arguments[idx][1], arguments[idx][0])
          elsif param.has_default?
            default_value = interpreter.interpret!(param.default_value, method_info[:env])
            method_env.set_local_var(param.name, default_value[1], default_value[0])
          else
            Utils.runtime_error("Brakujący argument '#{param.name}'", @line)
          end
        end

        # handle rest parameter
        if rest_param
          rest_args = arguments[rest_position..-1] || []
          rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
          method_env.set_local_var(rest_param.name, rest_array_elements, :type_array)
        end

        # execute static method body
        Utils::ContextTracker.current_class_name = @class_name
        Utils::CallStackTracker.push(:method, @method_name, interpreter.current_file, @line)
        begin
          interpreter.interpret!(method_info[:declaration].body_statement, method_env)
          result = [:type_null, Utils::NULL_VALUE]
        rescue Utils::ReturnError => e
          result = e.value
        ensure
          Utils::CallStackTracker.pop
        end

        result
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