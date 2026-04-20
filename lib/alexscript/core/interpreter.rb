# frozen_string_literal: true

module AlexScript
  module Core
    class Interpreter
      include Helpers::DeepEquality, Helpers::ValueFormatter, Helpers::TypeConverter,
              Helpers::ValidationHelper, Helpers::ExceptionHandler, Helpers::LambdaHelper

      # higher order array method names.  frozen Set for O(1) lookup
      ARRAY_HOF_METHODS = %w[mapuj filtruj redukuj kazdy znajdz dowolny wszystkie sortuj].freeze

      # Expose internal state to AST nodes that need it (ImportStmt reads current_file,
      # ClassInstantiation pushes current_file into the call stack tracker, etc.).
      attr_reader :import_manager, :current_file

      def initialize
        @import_manager = Utils::ImportManager.new
        @current_file = 'main'
      end

      def set_current_file(file)
        @current_file = file
        Utils::ContextTracker.current_file = file
      end

      # ── Main dispatcher ────────────────────────────────────────────────
      # All per-node-type logic lives as evaluate(interpreter, env) on each
      # AST class. This method stays small on purpose: it only runs the
      # cross-cutting hooks (line tracking, debugger step) and dispatches.
      def interpret!(node, env)
        Utils::ContextTracker.current_line = node.line if node.respond_to?(:line) # always set line first

        # debugger stepping hook
        Utils::Debugger.check(node, env, self) if Utils::Debugger.stepping?

        node.evaluate(self, env)
      end

      # ====================================================================
      # Function call — extracted from the old interpret! elsif chain.
      # Kept as an interpreter method (rather than inlined into AST::FuncCall)
      # because it's 270+ lines and deeply tied to interpreter-owned state.
      # Called from AST::FuncCall#evaluate.
      # ====================================================================
      def evaluate_func_call(node, env)
        env.increment_call_depth(node.line)
        begin
          # new code: first check if we're in a class instance context
          current_instance = env.get_instance
          class_method_called = false

          if current_instance
            # we're in an instance method - first look for method in current class
            # then in base classes (including private ones)

            # initialize variables to store found method
            method_info = nil
            found_class_def = nil

            # start from current class
            current_class_name = current_instance[:class_name]

            # go through class hierarchy searching for method
            while current_class_name && !method_info
              if current_instance[:module_path] && !current_instance[:module_path].empty?
                current_class_def = env.get_module_class(current_instance[:module_path], current_class_name)
              else
                current_class_def = env.get_class(current_class_name)
              end

              break unless current_class_def

              # check if method exists in this class
              if current_class_def[:methods] && current_class_def[:methods][node.name]
                method_info = current_class_def[:methods][node.name]
                found_class_def = current_class_def
                break
              end

              # move to base class
              current_class_name = current_class_def[:parent]
            end

            if method_info
              class_method_called = true

              # Native method called from inside instance (without sam.)
              if method_info[:native_lambda]
                arguments = node.arguments.map do |arg|
                  if arg.is_a?(AST::Identifier)
                    var = env.get_var(arg.name)
                    if var
                      [var[:type], var[:value]]
                    else
                      func_value = env.get_func_as_value(arg.name)
                      Utils.runtime_error("Niezdefiniowana zmienna lub funkcja #{arg.name}", arg.line) unless func_value
                      func_value
                    end
                  else
                    interpret!(arg, env)
                  end
                end

                native_obj = current_instance[:__native__]
                unless native_obj
                  Utils.runtime_error("Brak obiektu natywnego — upewnij się, że konstruktor wywołuje super()", node.line)
                end

                begin
                  result = Utils::NativeClassRegistry.dispatch_native_lambda(
                    method_info[:native_lambda], native_obj, arguments
                  )
                rescue => e
                  Utils.runtime_error("Błąd metody #{node.name}: #{e.message}", node.line)
                end
              else
                # this is a method call from class hierarchy (can be private)

                # evaluate arguments
                arguments = node.arguments.map do |arg|
                  if arg.is_a?(AST::Identifier)
                    var = env.get_var(arg.name)
                    if var
                      [var[:type], var[:value]]
                    else
                      func_value = env.get_func_as_value(arg.name)
                      Utils.runtime_error("Niezdefiniowana zmienna lub funkcja #{arg.name}", arg.line) unless func_value
                      func_value
                    end
                  else
                    interpret!(arg, env)
                  end
                end

                # handle parameters, similar to regular functions
                func_declr = method_info[:declaration]
                func_env = method_info[:env]

                # rest type parameters
                rest_param = func_declr.params.find(&:rest?)
                min_args = func_declr.params.count { |p| !p.has_default? && !p.rest? }
                max_args = rest_param ? Float::INFINITY : func_declr.params.size

                # validate argument count
                if node.arguments.size < min_args
                  Utils.runtime_error(
                    "Metoda #{node.name} oczekiwala minimum #{min_args} argumentów, otrzymała #{node.arguments.size}",
                    node.line
                  )
                end

                unless rest_param
                  if node.arguments.size > max_args
                    Utils.runtime_error(
                      "Metoda #{node.name} oczekiwala maksymalnie #{max_args} argumentów, otrzymała #{node.arguments.size}",
                      node.line
                    )
                  end
                end

                # create new environment for method
                new_func_env = func_env.new_env
                new_func_env.set_instance(current_instance)

                # handle regular parameters
                rest_idx = func_declr.params.index(&:rest?)
                rest_position = rest_idx || func_declr.params.size

                normal_params = func_declr.params.reject(&:rest?)
                normal_params.each_with_index do |param, idx|
                  if idx < node.arguments.size && (rest_idx.nil? || idx < rest_idx)
                    arg_val = arguments[idx]
                    new_func_env.set_local_var(param.name, arg_val[1], arg_val[0])
                  else
                    if param.has_default?
                      default_value = interpret!(param.default_value, func_env)
                      new_func_env.set_local_var(param.name, default_value[1], default_value[0])
                    else
                      Utils.runtime_error("Brakujacy argument #{param.name}", node.line)
                    end
                  end
                end

                # handle rest parameter
                if rest_param
                  rest_args = arguments[rest_position..-1] || []
                  rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
                  new_func_env.set_local_var(rest_param.name, rest_array_elements, :type_array)
                end

                # execute method body
                Utils::CallStackTracker.push(:function, node.name, @current_file, node.line)
                begin
                  Utils::ContextTracker.track_method_call(node.name) do
                    interpret!(func_declr.body_statement, new_func_env)
                  end
                  result = [:type_null, Utils::NULL_VALUE]
                rescue Utils::ReturnError => e
                  result = e.value
                ensure
                  Utils::CallStackTracker.pop
                end
              end
            end
          end

          # end of new code - proceed to standard function handling
          # if no class method was found
          unless class_method_called
            var = env.get_var(node.name)

            Utils.runtime_error("Niepoprawna wartosc funkcji dla #{node.name}", node.line) if var && !validate_function_value(var)

            if var && var[:type] == :type_function
              # if it's a variable containing function
              func_declr = var[:value][:declaration]
              func_env = var[:value][:env]
            else
              # if not, just check for a regular function
              func = env.get_func(node.name)
              Utils.runtime_error("Funkcja #{node.name} nie zostala zadeklarowana w obecnym zakresie", node.line) unless func
              # fetch function declaration
              func_declr = func[0] # entire func declaration
              func_env   = func[1] # function env
            end

            # check if there is a rest (*args) param in funct call
            rest_param = func_declr.params.find(&:rest?)

            min_args = func_declr.params.count { |p| !p.has_default? && !p.rest? }
            max_args = rest_param ? Float::INFINITY : func_declr.params.size

            if node.arguments.size < min_args
              Utils.runtime_error(
                "Funkcja #{node.name} oczekiwala minimum #{min_args} argumentów, otrzymała #{node.arguments.size}",
                node.line
              )
            end

            # check max number of args if rest param is not present
            unless rest_param
              if node.arguments.size > max_args
                Utils.runtime_error(
                  "Funkcja #{node.name} oczekiwala maksymalnie #{max_args} argumentów, otrzymała #{node.arguments.size}",
                  node.line
                )
              end
            end

            # evaluate args
            arguments = node.arguments.map do |arg|
              if arg.is_a?(AST::Identifier)
                # try to fetch it as a variable
                var = env.get_var(arg.name)
                if var
                  [var[:type], var[:value]]
                else
                  # if var not found, try to fetch a function
                  func_value = env.get_func_as_value(arg.name)
                  Utils.runtime_error("Niezdefiniowana zmienna lub funkcja #{arg.name}", arg.line) unless func_value
                  func_value
                end
              else
                interpret!(arg, env)
              end
            end

            # new nested env for function
            new_func_env = func_env.new_env

            # index of the rest param
            rest_idx = func_declr.params.index(&:rest?)
            rest_position = rest_idx || func_declr.params.size

            # assign values to regular parameters (before rest parameter)
            normal_params = func_declr.params.reject(&:rest?)
            normal_params.each_with_index do |param, idx|
              if idx < node.arguments.size && (rest_idx.nil? || idx < rest_idx)
                # use passed argument
                arg_val = arguments[idx]
                new_func_env.set_local_var(param.name, arg_val[1], arg_val[0])
              else
                # use default value
                if param.has_default?
                  default_value = interpret!(param.default_value, func_env)
                  new_func_env.set_local_var(param.name, default_value[1], default_value[0])
                else
                  Utils.runtime_error("Brakujacy argument #{param.name}", node.line)
                end
              end
            end

            # handle rest parameter if exists
            if rest_param
              rest_args = arguments[rest_position..-1] || []

              rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
              new_func_env.set_local_var(rest_param.name, rest_array_elements, :type_array)
            end

            # interpret function declaration body
            Utils::CallStackTracker.push(:function, node.name, @current_file, node.line) # for exception handler
            begin
              Utils::ContextTracker.track_method_call(node.name) do
                if func_declr.respond_to?(:implicit_return?) && func_declr.implicit_return?
                  result = interpret!(func_declr.body_statement.stmts[0].expression, new_func_env)
                else
                  interpret!(func_declr.body_statement, new_func_env)
                  result = [:type_null, Utils::NULL_VALUE]
                end
              end
            rescue Utils::ReturnError => e
              result = e.value
            ensure
              Utils::CallStackTracker.pop
            end
          end
          result
        ensure
          env.decrement_call_depth
        end
      end

      # ====================================================================
      # Method call — extracted from the old interpret! elsif chain.
      # Handles :type_class (static methods), :type_instance (instance methods),
      # and fallback to built-in methods for arrays/objects/primitives.
      # Called from AST::MethodCall#evaluate.
      # ====================================================================
      def evaluate_method_call(node, env)
        # interpret object
        object_type, object_value = interpret!(node.object, env)

        # check if this is a method call on a class value.
        # covers both direct Identifier (rarely reached — see Identifier handler)
        # AND ModuleAccess resolving to a class (Test::Cos.static_method()).
        if object_type == :type_class
          class_def = object_value

          # class_name: best-effort for error messages and reflection
          class_name =
            if node.object.is_a?(AST::Identifier)
              node.object.name
            elsif node.object.is_a?(AST::ModuleAccess)
              node.object.member_name
            else
              class_def[:name] || "<nieznana>"
            end

          # module_path: if we came via a module, parent lookups for inheritance
          # must also happen within that module before falling back to global classes.
          module_path =
            node.object.is_a?(AST::ModuleAccess) ? node.object.module_path : nil

          # first check if this is a built-in info method for class
          begin
            # prepare arguments
            evaluated_args = node.arguments.map { |arg| interpret!(arg, env)[1] }

            # add class name info to definition (idempotent)
            class_def[:name] ||= class_name

            # add environment access for methods that need it
            evaluated_args.unshift(env) if [:przodkowie, :czy_dziedziczy_po].include?(node.method_name.to_sym)

            # try to call built-in class method
            result = env.call_method(:type_class, node.method_name, class_def, evaluated_args)

            # determine result type
            result_type = case result
                          when Integer then :type_int
                          when Float then :type_float
                          when String then :type_string
                          when TrueClass, FalseClass then :type_bool
                          when Array then :type_array
                          when NilClass then :type_null
                          when Hash then :type_object
                          else
                            :type_object # default treat as object
                          end

            return [result_type, result]
          rescue StandardError => e
            # if no built-in method, continue with normal static methods
          end

          # look for static method in class hierarchy
          method_info = nil
          current_class_def = class_def

          while current_class_def && !method_info
            # check if method exists in current class
            if current_class_def[:static_methods] && current_class_def[:static_methods][node.method_name]
              method_info = current_class_def[:static_methods][node.method_name]
              break
            end

            # if not, check base class
            parent_name = current_class_def[:parent]
            break unless parent_name

            # module-aware parent lookup: try the same module first, fall back to global
            current_class_def =
              if module_path
                env.get_module_class(module_path, parent_name) || env.get_class(parent_name)
              else
                env.get_class(parent_name)
              end
          end

          if method_info
            # native static via hierarchy
            if method_info[:native_lambda]
              arguments = node.arguments.map { |arg| interpret!(arg, env) }
              begin
                result = Utils::NativeClassRegistry.dispatch_static_lambda(method_info[:native_lambda], arguments)
              rescue => e
                Utils.runtime_error("Błąd metody statycznej #{node.method_name}: #{e.message}", node.line)
              end
              return result
            end


            # handle static method call

            # evaluate arguments
            arguments = node.arguments.map { |arg| interpret!(arg, env) }

            # check argument count
            params = method_info[:declaration].params

            # handle rest type parameters
            rest_param = params.find(&:rest?)
            min_args = params.count { |p| !p.has_default? && !p.rest? }
            max_args = rest_param ? Float::INFINITY : params.size

            if arguments.size < min_args
              Utils.runtime_error(
                "Metoda statyczna #{node.method_name} oczekiwała, a minimum #{min_args} argumentów, otrzymała #{arguments.size}",
                node.line
              )
            end

            unless rest_param
              if arguments.size > max_args
                Utils.runtime_error(
                  "Metoda statyczna #{node.method_name} oczekiwała, a maksymalnie #{max_args} argumentów, otrzymała #{arguments.size}",
                  node.line
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
                default_value = interpret!(param.default_value, method_info[:env])
                method_env.set_local_var(param.name, default_value[1], default_value[0])
              else
                Utils.runtime_error("Brakujący argument #{param.name}", node.line)
              end
            end

            # handle rest parameter
            if rest_param
              rest_args = arguments[rest_position..-1] || []
              rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
              method_env.set_local_var(rest_param.name, rest_array_elements, :type_array)
            end

            # execute static method body
            Utils::ContextTracker.current_class_name = object_value[:class_name]
            Utils::CallStackTracker.push(:method, node.method_name, @current_file, node.line)
            begin
              Utils::ContextTracker.track_method_call(node.method_name) do
                interpret!(method_info[:declaration].body_statement, method_env)
              end
              result = [:type_null, Utils::NULL_VALUE]  # by default return 'nic'
            rescue Utils::ReturnError => e
              result = e.value  # or specific value returned by method
            ensure
              Utils::CallStackTracker.pop
            end

            return result
          else
            # Fallback: static variable access via dot on a module class value.
            # e.g., Test::Cos.STALA — parsed as MethodCall(ModuleAccess, "STALA", []).
            # For direct uppercase identifiers, parser builds AST::StaticVariable
            # instead and this path isn't taken.
            if node.method_name.match?(/^[A-Z_]+$/) && node.arguments.empty?
              static_def = nil
              lookup_class = class_def
              while lookup_class && !static_def
                if lookup_class[:static_vars] && lookup_class[:static_vars][node.method_name]
                  static_def = lookup_class[:static_vars][node.method_name]
                  break
                end
                parent_name = lookup_class[:parent]
                break unless parent_name
                lookup_class =
                  if module_path
                    env.get_module_class(module_path, parent_name) || env.get_class(parent_name)
                  else
                    env.get_class(parent_name)
                  end
              end
              return [static_def[:type], static_def[:value]] if static_def
            end

            Utils.runtime_error("Nieznana metoda statyczna '#{node.method_name}' w klasie #{class_name}", node.line)
          end
        end

        # handle class instance methods
        if object_type == :type_instance
          # first check if this is a built-in info method for instance
          if env.built_in_methods.get_method(:type_instance, node.method_name)
            evaluated_args = node.arguments.map { |arg| interpret!(arg, env)[1] }

            result = env.call_method(:type_instance, node.method_name, object_value, evaluated_args)

            # Sprawdz czy juz zwrocone jako tuple
            if result.is_a?(Array) && result.size == 2 && result[0].is_a?(Symbol)
              return result
            end

            # conver Ruby vals to AlexScript
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


          # find method in class hierarchy
          method_result = env.find_method_in_hierarchy(object_value, node.method_name)
          Utils.runtime_error("Nieznana metoda #{node.method_name} dla instancji klasy #{object_value[:class_name]}", node.line) unless method_result

          method_info = method_result[:method_info]

          # native method dispatch (inherited or direct)
          if method_info[:native_lambda]
            # Check privacy
            if method_info[:private]
              current_instance = env.get_instance
              same_instance = current_instance == object_value
              from_inside_class = current_instance && current_instance[:class_name] == object_value[:class_name]
              from_subclass = current_instance && env.is_subclass_of(current_instance[:class_name], object_value[:class_name])
              unless same_instance || from_inside_class || from_subclass
                Utils.runtime_error("Próba wywołania prywatnej metody #{node.method_name}", node.line)
              end
            end

            arguments = node.arguments.map { |arg| interpret!(arg, env) }
            native_obj = object_value[:__native__]

            unless native_obj
              Utils.runtime_error("Brak obiektu natywnego — upewnij się, że konstruktor wywołuje super()", node.line)
            end

            begin
              result = Utils::NativeClassRegistry.dispatch_native_lambda(
                method_info[:native_lambda], native_obj, arguments
              )
            rescue => e
              Utils.runtime_error(
                "Błąd metody #{node.method_name}: #{e.message}",
                node.line
              )
            end
            return result
          end

          # check if method is private
          if method_info[:private]
            current_instance = env.get_instance
            # private method can be called:
            # 1. from same instance
            # 2. from methods of same class (or subclass if inherited)

            same_instance = current_instance == object_value
            from_inside_class = current_instance && current_instance[:class_name] == object_value[:class_name]
            from_subclass = current_instance && env.is_subclass_of(current_instance[:class_name], object_value[:class_name])

            unless same_instance || from_inside_class || from_subclass
              Utils.runtime_error("Próba wywołania prywatnej metody #{node.method_name}", node.line)
            end
          end

          # evaluate arguments
          arguments = node.arguments.map { |arg| interpret!(arg, env) }

          # check argument count
          params = method_info[:declaration].params

          # handle rest type parameters
          rest_param = params.find(&:rest?)
          min_args = params.count { |p| !p.has_default? && !p.rest? }
          max_args = rest_param ? Float::INFINITY : params.size

          if arguments.size < min_args
            Utils.runtime_error(
              "Metoda #{node.method_name} oczekiwała, a minimum #{min_args} argumentów, otrzymała #{arguments.size}",
              node.line
            )
          end

          unless rest_param
            if arguments.size > max_args
              Utils.runtime_error(
                "Metoda #{node.method_name} oczekiwała, a maksymalnie #{max_args} argumentów, otrzymała #{arguments.size}",
                node.line
              )
            end
          end

          # create new environment for method
          method_env = method_info[:env].new_env
          method_env.set_instance(object_value)

          # assign arguments to parameters
          rest_idx = params.index(&:rest?)
          rest_position = rest_idx || params.size

          normal_params = params.reject(&:rest?)
          normal_params.each_with_index do |param, idx|
            if idx < arguments.size && (rest_idx.nil? || idx < rest_idx)
              method_env.set_local_var(param.name, arguments[idx][1], arguments[idx][0])
            elsif param.has_default?
              default_value = interpret!(param.default_value, method_info[:env])
              method_env.set_local_var(param.name, default_value[1], default_value[0])
            else
              Utils.runtime_error("Brakujący argument #{param.name}", node.line)
            end
          end

          # handle rest parameter
          if rest_param
            rest_args = arguments[rest_position..-1] || []
            rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
            method_env.set_local_var(rest_param.name, rest_array_elements, :type_array)
          end

          # execute method body
          Utils::ContextTracker.current_class_name = object_value[:class_name]
          Utils::CallStackTracker.push(:method, node.method_name, @current_file, node.line)
          begin
            Utils::ContextTracker.track_method_call(node.method_name) do
              interpret!(method_info[:declaration].body_statement, method_env)
            end
            result = [:type_null, Utils::NULL_VALUE]  # by default return 'nic'
          rescue Utils::ReturnError => e
            result = e.value  # or specific value returned by method
          ensure
            Utils::CallStackTracker.pop
          end

          result
        else
          # keep existing handling for regular object methods
          Utils.runtime_error('Nie można wywolac metody na niezdefiniowanym obiekcie', node.line) unless object_value

          # Higher-order array methods — intercept before call_method
          # because these need interpreter access to invoke fn callbacks
          if object_type == :type_array && ARRAY_HOF_METHODS.include?(node.method_name)
            return interpret_array_hof(node.method_name, object_value, node, env)
          end

          # evaluate method arguments
          evaluated_args = node.arguments.map { |arg| interpret!(arg, env)[1] }

          begin
            result = env.call_method(object_type, node.method_name, object_value, evaluated_args)
            if result.is_a?(Array) && result.size == 2 && result[0].is_a?(Symbol)
              result
            else
              # determine result type
              result_type = case result
                            when Integer then :type_int
                            when Float then :type_float
                            when String then :type_string
                            when TrueClass, FalseClass then :type_bool
                            when Array then :type_array
                            when NilClass then :type_null
                            when Hash then :type_object
                            else
                              Utils.runtime_error("Niespodziewany typ zwrocony z metody #{node.method_name}", node.line)
                            end
              [result_type, result]
            end
          rescue StandardError => e
            Utils.runtime_error("Blad podczas wykonywania metody #{node.method_name}: #{e.message}", node.line)
          end
        end
      end

      # ====================================================================
      # Helpers used by AST nodes — unchanged from the pre-refactor interpreter.
      # ====================================================================

      def stringify_for_interpolation(type, value)
        case type
        when :type_string then value.to_s
        when :type_null then 'nic'
        when :type_bool then value == Utils::BOOL_TRUE ? 'prawda' : 'falsz'
        when :type_int, :type_float then value.to_s
        when :type_array then format_array_value(value).to_s
        when :type_object then format_object_value(value)
        when :type_function then '<funkcja>'
        when :type_instance then "<#{value[:class_name]} instancja>"
        else value.to_s
        end
      end

      # ── Lambda/fn call execution ──────────────────────────────────────
      # Extracted as a method to keep interpret! lean. Handles:
      # - IIFE: fn(x){ x * 2 }(5)
      # - Chained calls: fn(){ fn(x){ x } }()(42)
      # - Any expression that evaluates to :type_function
      def interpret_lambda_call(node, env)
        callee_type, callee_value = interpret!(node.callee, env)

        unless callee_type == :type_function
          Utils.runtime_error("Próba wywołania wartości niebędącej funkcją", node.line)
        end

        func_declr = callee_value[:declaration]
        func_env = callee_value[:env]
        call_name = func_declr.respond_to?(:name) ? func_declr.name : '<fn>'

        # Validate argument count
        rest_param = func_declr.params.find(&:rest?)
        min_args = func_declr.params.count { |p| !p.has_default? && !p.rest? }

        if node.arguments.size < min_args
          Utils.runtime_error(
            "Funkcja #{call_name} oczekiwała minimum #{min_args} argumentów, otrzymała #{node.arguments.size}",
            node.line
          )
        end

        unless rest_param
          max_args = func_declr.params.size
          if node.arguments.size > max_args
            Utils.runtime_error(
              "Funkcja #{call_name} oczekiwała maksymalnie #{max_args} argumentów, otrzymała #{node.arguments.size}",
              node.line
            )
          end
        end

        # Evaluate arguments
        arguments = node.arguments.map do |arg|
          if arg.is_a?(AST::Identifier)
            var = env.get_var(arg.name)
            if var
              [var[:type], var[:value]]
            else
              func_value = env.get_func_as_value(arg.name)
              Utils.runtime_error("Niezdefiniowana zmienna lub funkcja #{arg.name}", arg.line) unless func_value
              func_value
            end
          else
            interpret!(arg, env)
          end
        end

        # Create execution environment from closure env
        new_func_env = func_env.new_env

        # Propagate instance context for fn used inside class methods
        current_instance = env.get_instance
        new_func_env.set_instance(current_instance) if current_instance

        # Assign parameters
        rest_idx = func_declr.params.index(&:rest?)
        rest_position = rest_idx || func_declr.params.size

        normal_params = func_declr.params.reject(&:rest?)
        normal_params.each_with_index do |param, idx|
          if idx < arguments.size && (rest_idx.nil? || idx < rest_idx)
            new_func_env.set_local_var(param.name, arguments[idx][1], arguments[idx][0])
          elsif param.has_default?
            default_value = interpret!(param.default_value, func_env)
            new_func_env.set_local_var(param.name, default_value[1], default_value[0])
          else
            Utils.runtime_error("Brakujący argument #{param.name}", node.line)
          end
        end

        if rest_param
          rest_args = arguments[rest_position..-1] || []
          rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
          new_func_env.set_local_var(rest_param.name, rest_array_elements, :type_array)
        end

        # Execute body
        env.increment_call_depth(node.line)
        Utils::CallStackTracker.push(:function, call_name, @current_file, node.line)
        begin
          result = nil
          Utils::ContextTracker.track_method_call(call_name) do
            if func_declr.respond_to?(:implicit_return?) && func_declr.implicit_return?
              result = interpret!(func_declr.body_statement.stmts[0].expression, new_func_env)
            else
              interpret!(func_declr.body_statement, new_func_env)
              result = [:type_null, Utils::NULL_VALUE]
            end
          end
        rescue Utils::ReturnError => e
          result = e.value
        ensure
          Utils::CallStackTracker.pop
        end
        env.decrement_call_depth
        result
      end

      # entry point of interpreter creating brand new global/parent environment
      def interpret_ast(node, env = nil)
        begin
          environment = env || Environment.new
          interpret!(node, environment)
        rescue Utils::AlexScriptError => e
          raise e
        rescue StandardError => e
          # translate and re-raise
          alex_error = Utils::ExceptionsTranslator.translate(e)
          raise alex_error
        end
      end
    end
  end
end