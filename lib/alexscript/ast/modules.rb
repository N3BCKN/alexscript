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

      def evaluate(interpreter, env)
        # ── Locate existing module for reopen, or prepare fresh one ──
        # Modules are open: multiple `modul Foo { ... }` blocks (in the same
        # file or across imported files) all contribute to a single module
        # definition. Conflict policy:
        #   - constants  → runtime error on redefinition (strict)
        #   - functions  → silent overwrite (Ruby-style reopen)
        #   - classes    → reopened in place; methods merge/overwrite
        #   - nested     → recursive reopen
        existing_module_def =
          if @parent_module.nil?
            env.get_module(@name)
          else
            parent_path = @parent_module.split("::")
            parent_def = env.resolve_module_path(parent_path)
            parent_def && parent_def[:nested_modules] && parent_def[:nested_modules][@name]
          end

        if existing_module_def
          module_def = existing_module_def
          module_env = module_def[:module_env]
        else
          module_def = {
            name: @name,
            classes: {},
            functions: {},
            constants: {},
            nested_modules: {},
            parent_module: @parent_module
          }
          module_env = env.new_env
          module_def[:module_env] = module_env
        end

        # ── Phase 1: constants and functions ──
        @body.stmts.each do |stmt|
          if stmt.is_a?(AST::VariableDeclaration)
            var_name = stmt.left.name
            if var_name.match?(/^[A-Z_]+$/)
              # CONFLICT POLICY: constants are strict.
              # Redefinition is almost always a bug, never intent.
              if module_def[:constants].key?(var_name)
                Utils.runtime_error(
                  "Stała '#{var_name}' jest już zdefiniowana w module #{@name}",
                  stmt.line
                )
              end
              value_type, value_value = interpreter.interpret!(stmt.right, module_env)
              module_def[:constants][var_name] = { type: value_type, value: value_value }
              # save constants in module_env for classes
              module_env.set_local_var(var_name, value_value, value_type, true)
            else
              Utils.runtime_error("Tylko stałe (WIELKIE_LITERY) mogą być definiowane w module", stmt.line)
            end
          elsif stmt.is_a?(AST::FuncDclr)
            # CONFLICT POLICY: functions silently overwrite.
            # Reopen is often used precisely to swap implementations.
            module_def[:functions][stmt.name] = [stmt, module_env]
            # save function in module_env
            module_env.set_func(stmt.name, [stmt, module_env])
          end
        end

        # ── Phase 2: classes + nested modules ──
        @body.stmts.each do |stmt|
          if stmt.is_a?(AST::ClassDefinition)
            # CONFLICT POLICY: class reopen — preserve identity, merge members.
            class_def = module_def[:classes][stmt.name]

            if class_def.nil?
              # First definition of this class within the module
              class_def = {
                parent: stmt.parent_class,
                body: stmt.body,
                methods: {},
                static_methods: {},
                static_vars: {},
                is_abstract: stmt.is_abstract
              }
              module_def[:classes][stmt.name] = class_def
              # expose the class to code inside the module so `Klasa.nowy()`
              # works without the full Modul::Klasa prefix
              module_env.define_class(stmt.name, class_def)
            else
              # Reopen: disallow changing the superclass mid-flight.
              # Empty re-declaration (no parent) is OK and means "just add members".
              if stmt.parent_class && class_def[:parent] && stmt.parent_class != class_def[:parent]
                Utils.runtime_error(
                  "Klasa #{stmt.name} w module #{@name} już dziedziczy po #{class_def[:parent]}, " \
                  "nie można zmienić na #{stmt.parent_class}",
                  stmt.line
                )
              end
              # Allow adding inheritance on reopen if original had none.
              class_def[:parent] ||= stmt.parent_class if stmt.parent_class
            end

            # process class body
            in_private = false
            in_static = false

            stmt.body.stmts.each do |class_stmt|
              if class_stmt.is_a?(AST::PrivateSection)
                in_private = true
              elsif class_stmt.is_a?(AST::StaticKeyword)
                in_static = true
              elsif class_stmt.is_a?(AST::IncludeModule)
                included_module_name = class_stmt.module_name
                included_module_def = nil

                # first, search in nested_modules of the same parent module (sibling)
                if module_def[:nested_modules] && module_def[:nested_modules][included_module_name]
                  included_module_def = module_def[:nested_modules][included_module_name]
                else
                  # if not found locally, search globally
                  included_module_def = env.get_module(included_module_name)
                end

                unless included_module_def
                  Utils.runtime_error("Nie znaleziono modułu #{included_module_name}", class_stmt.line)
                end


                # copy functions from module as instance methods
                if included_module_def[:functions]
                  included_module_def[:functions].each do |func_name, func_data|
                    # don't overwrite if class already has this method
                    if class_def[:methods].key?(func_name)
                      next
                    end

                    class_def[:methods][func_name] = {
                      declaration: func_data[0],
                      env: func_data[1],  # use env from module
                      private: in_private
                    }
                  end
                end

                # copy constants from module to module_env
                if included_module_def[:constants]
                  included_module_def[:constants].each do |const_name, const_data|
                    module_env.set_local_var(const_name, const_data[:value], const_data[:type], true)
                  end
                end

              elsif class_stmt.is_a?(AST::FuncDclr)
                # CONFLICT POLICY: method reopen silently overwrites (Ruby-style).
                if in_static
                  class_def[:static_methods][class_stmt.name] = {
                    declaration: class_stmt,
                    env: module_env,
                    private: in_private
                  }
                  in_static = false
                else
                  class_def[:methods][class_stmt.name] = {
                    declaration: class_stmt,
                    env: module_env,
                    private: in_private
                  }
                end
              elsif class_stmt.is_a?(AST::VariableDeclaration) && in_static
                value_type, value_value = interpreter.interpret!(class_stmt.right, module_env)
                class_def[:static_vars][class_stmt.left.name] = { type: value_type, value: value_value }
                in_static = false
              end
            end

          elsif stmt.is_a?(AST::ModuleDefinition)
            # nested module — recurse; reopen is handled inside the recursive call
            # (same ModuleDefinition handler, looks up via parent_module path).
            nested_module_def = interpreter.interpret!(stmt, module_env)
            # Overwriting with the same object on reopen is a no-op (identity).
            module_def[:nested_modules][stmt.name] = nested_module_def
            # expose nested modules to siblings: inside Parser you can write
            # Codes::... instead of the fully qualified Zubr::Codes::...
            module_env.define_module(stmt.name, nested_module_def)
          end
        end

        module_def.delete(:body) if module_def.key?(:body)

        # Register top-level modules. Re-registration is a no-op (same object).
        if @parent_module.nil?
          env.define_module(@name, module_def)
        end

        module_def
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

        @module_path = module_path
        @member_name = member_name
        @line = line
      end

      def evaluate(_interpreter, env)
        # Modul::funkcja() or Modul::STALA
        module_path = @module_path
        member_name = @member_name

        # try function first
        func = env.get_module_function(module_path, member_name)
        if func
          return [:type_function, { declaration: func[0], env: func[1] }]
        end

        # try constant
        constant = env.get_module_constant(module_path, member_name)
        if constant
          return [constant[:type], constant[:value]]
        end

        # try class (for static access)
        class_def = env.get_module_class(module_path, member_name)
        if class_def
          return [:type_class, class_def]
        end

        # Fallback: maybe module_path.last is a class, and member_name is its
        # static variable. E.g., Test::Cos::STALA — treats `::` as equivalent to `.`
        # for static-variable access on classes.
        if member_name.match?(/^[A-Z_]+$/)
          class_name = module_path.last
          parent_path = module_path[0...-1]
          host_class =
            if parent_path.empty?
              env.get_class(class_name)
            else
              env.get_module_class(parent_path, class_name)
            end

          if host_class
            lookup_class = host_class
            while lookup_class
              if lookup_class[:static_vars] && lookup_class[:static_vars][member_name]
                static_def = lookup_class[:static_vars][member_name]
                return [static_def[:type], static_def[:value]]
              end
              parent_name = lookup_class[:parent]
              break unless parent_name
              lookup_class =
                (parent_path.any? ? env.get_module_class(parent_path, parent_name) : nil) ||
                env.get_class(parent_name)
            end
          end
        end

        path_str = module_path.join("::")
        Utils.runtime_error("Nie znaleziono '#{member_name}' w module #{path_str}", @line)
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

      def evaluate(interpreter, env)
        # Modul::Klasa.nowy(args)
        module_path = @module_path
        class_name = @class_name

        class_def = env.get_module_class(module_path, class_name)

        unless class_def
          path_str = module_path.join("::")
          Utils.runtime_error("Nie znaleziono klasy #{class_name} w module #{path_str}", @line)
        end

        if class_def[:is_abstract]
          Utils.runtime_error("Nie można utworzyć instancji klasy abstrakcyjnej #{class_name}", @line)
        end

        # native class constructor (in module)
        if class_def[:native]
          arguments = @arguments.map { |arg| interpreter.interpret!(arg, env) }

          begin
            native_obj = Utils::NativeClassRegistry.dispatch_constructor(class_name, arguments)
          rescue => e
            Utils.runtime_error("Błąd konstruktora natywnego #{class_name}: #{e.message}", @line)
          end

          instance = {
            class_name: class_name,
            module_path: module_path,
            instance_vars: {},
            class_def: class_def,
            __native__: native_obj
          }
          return [:type_instance, instance]
        end

        # create instance like normal
        instance = {
          class_name: class_name,
          module_path: module_path,  # track module origin
          instance_vars: {},
          class_def: class_def
        }

        constructor = resolve_constructor(class_def, env)

        if constructor
          arguments = @arguments.map { |arg| interpreter.interpret!(arg, env) }

          constructor_env = constructor[:env].new_env
          constructor_env.set_instance(instance)

          # precomputed param metadata (see FuncDclr#initialize)
          decl          = constructor[:declaration]
          rest_param    = decl.rest_param
          min_args      = decl.min_args
          max_args      = decl.max_args
          rest_idx      = decl.rest_idx
          normal_params = decl.normal_params

          if arguments.size < min_args
            Utils.runtime_error("Konstruktor oczekiwał minimum #{min_args} argumentów, otrzymał #{arguments.size}", @line)
          end

          unless rest_param
            if arguments.size > max_args
              Utils.runtime_error("Konstruktor oczekiwał maksymalnie #{max_args} argumentów, otrzymał #{arguments.size}", @line)
            end
          end

          # assign params
          rest_position = rest_idx || decl.params.size


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

          if rest_param
            rest_args = arguments[rest_position..-1] || []
            rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
            constructor_env.set_local_var(rest_param.name, rest_array_elements, :type_array)
          end

          # execute constructor
          Utils::CallStackTracker.push(:constructor, class_name, interpreter.current_file, @line)
          catch(:alex_return) do
            begin
              Utils::ContextTracker.track_class_context(class_name) do
                Utils::ContextTracker.track_method_call("konstruktor") do
                  interpreter.interpret!(constructor[:declaration].body_statement, constructor_env)
                end
              end
            ensure
              Utils::CallStackTracker.pop
            end
          end
        end

        [:type_instance, instance]
      end

      private

      # Looks up konstruktor in the class itself, then walks up the inheritance
      # chain to find the nearest ancestor's konstruktor. Returns nil if no
      # constructor is found anywhere in the chain (in which case the instance
      # is created with empty instance_vars). Native ancestors halt the walk —
      # they are handled separately at the call site.
      def resolve_constructor(class_def, env)
        return class_def[:methods]["konstruktor"] if class_def[:methods]["konstruktor"]

        ancestor = class_def
        while ancestor[:parent]
          parent_def = lookup_parent_class(ancestor[:parent], env)
          return nil unless parent_def
          return nil if parent_def[:native]
          return parent_def[:methods]["konstruktor"] if parent_def[:methods] && parent_def[:methods]["konstruktor"]
          ancestor = parent_def
        end

        nil
      end

      # Looks up a parent class by name — first in the same module as the
      # instantiated class, then falls back to the global scope. Mirrors the
      # lookup pattern used by find_method_in_hierarchy and is_subclass_of for
      # correct cross-module inheritance.
      def lookup_parent_class(name, env)
        env.get_module_class(@module_path, name) || env.get_class(name)
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

      def evaluate(interpreter, env)
        # Modul::funkcja(args)
        module_path = @module_path
        function_name = @function_name

        func = env.get_module_function(module_path, function_name)

        # Fallback: maybe the last path segment is a class, and function_name
        # is its static method. E.g., Test::Cos::moja_funkcja() — Cos is a
        # class in module Test, not a nested module. Treats `::` as equivalent
        # to `.` for static-method access.
        unless func
          class_name = module_path.last
          parent_path = module_path[0...-1]
          class_def =
            if parent_path.empty?
              env.get_class(class_name)
            else
              env.get_module_class(parent_path, class_name)
            end

          if class_def
            # Re-dispatch through the appropriate AST shape so all existing
            # static-method logic (hierarchy walk, native dispatch, built-ins)
            # applies uniformly.
            if parent_path.empty?
              synthetic = AST::StaticMethodCall.new(class_name, function_name, @arguments, @line)
            else
              module_access = AST::ModuleAccess.new(parent_path, class_name, @line)
              synthetic = AST::MethodCall.new(module_access, function_name, @arguments, @line)
            end
            return interpreter.interpret!(synthetic, env)
          end
        end

        unless func
          path_str = module_path.join("::")
          Utils.runtime_error("Nie znaleziono funkcji '#{function_name}' w module #{path_str}", @line)
        end

        # func to [declaration, env]
        func_declr = func[0]
        func_env = func[1]

        # Async dispatch: if the resolved function is async, delegate to
        # interpreter's async path rather than executing its body synchronously.
        if func_declr.respond_to?(:async) && func_declr.async
          # Synthesize a FuncCall node so evaluate_async_func_call can use it
          # uniformly; the interpreter's async helper reads node.name, node.line
          # and node.arguments.
          synthetic = AST::FuncCall.new(@function_name, @arguments, @line)
          return interpreter.evaluate_async_func_call(
            synthetic, env, func_declr, func_env, instance: nil
          )
        end

        # evaluate arguments
        arguments = @arguments.map { |arg| interpreter.interpret!(arg, env) }

        # validate argument count — precomputed param metadata (see FuncDclr#initialize)
        rest_param    = func_declr.rest_param
        min_args      = func_declr.min_args
        max_args      = func_declr.max_args
        rest_idx      = func_declr.rest_idx
        normal_params = func_declr.normal_params

        if arguments.size < min_args
          Utils.runtime_error(
            "Funkcja #{function_name} oczekiwała minimum #{min_args} argumentów, otrzymała #{arguments.size}",
            @line
          )
        end

        unless rest_param
          if arguments.size > max_args
            Utils.runtime_error(
              "Funkcja #{function_name} oczekiwała maksymalnie #{max_args} argumentów, otrzymała #{arguments.size}",
              @line
            )
          end
        end

        # create new env for function
        new_func_env = func_env.new_env

        # assign parameters
        rest_position = rest_idx || func_declr.params.size


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

        # execute function
        env.increment_call_depth(@line)
        Utils::CallStackTracker.push(:function, function_name, interpreter.current_file, @line)
        result = catch(:alex_return) do
          begin
            Utils::ContextTracker.track_method_call(function_name) do
              interpreter.interpret!(func_declr.body_statement, new_func_env)
            end
            [:type_null, Utils::NULL_VALUE]
          ensure
            Utils::CallStackTracker.pop
            env.decrement_call_depth
          end
        end

        result
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

      # IncludeModule is a structural marker consumed by ClassDefinition /
      # ModuleDefinition during their evaluate. No-op if it ever reaches dispatch.
      def evaluate(_interpreter, _env)
        [:type_null, Utils::NULL_VALUE]
      end

      def pretty_print(level = 0)
        "#{indent(level)}IncludeModule(#{@module_name})"
      end
    end
  end
end