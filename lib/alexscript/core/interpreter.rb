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

      # Function call — extracted from the old interpret! elsif chain.
      # Kept as an interpreter method (rather than inlined into AST::FuncCall)
      # because it's 270+ lines and deeply tied to interpreter-owned state.
      # Called from AST::FuncCall#evaluate
      def evaluate_func_call(node, env)
        # ── Built-in async functions ─────────────────────────────────────
        if AlexScript::Async::Builtins.builtin?(node.name)
          return AlexScript::Async::Builtins.dispatch(node.name, node, env, self)
        end

        # ── Async dispatch ────────────────────────────────────────────────
        # If the called function is marked `asynchroniczna`, spawn a fiber,
        # return a Promise immediately, and let the reactor run the body.
        # We resolve the declaration here (same way the sync path does below)
        # and delegate to evaluate_async_func_call.
        #
        # Detection happens BEFORE we increment call_depth — async fibers
        # manage their own depth inside the fiber body.
        func_info = resolve_func_for_async_check(node, env)
        if func_info && func_info[:func_declr].async
          return evaluate_async_func_call(
            node, env, func_info[:func_declr], func_info[:func_env],
            instance: func_info[:instance]
          )
        end

        # ── Sync path (existing behavior) ─────────────────────────────────
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

                # rest type parameters — read precomputed metadata from declaration
                rest_param = func_declr.rest_param
                min_args = func_declr.min_args
                max_args = func_declr.max_args

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
                rest_idx = func_declr.rest_idx
                rest_position = rest_idx || func_declr.params.size

                normal_params = func_declr.normal_params
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

            # Native lambda shortcut 
            # Some :type_function values wrap a Ruby proc. Dispatch directly,
            # bypassing AS body interpretation.
            if func_declr.native_lambda
              arguments = node.arguments.map { |arg| interpret!(arg, env) }
              result = func_declr.native_lambda.call(*arguments)
              return result if result.is_a?(Array) && result.size == 2 && result[0].is_a?(Symbol)
              return [:type_null, Utils::NULL_VALUE]
            end

            # check if there is a rest (*args) param in funct call
            rest_param = func_declr.rest_param

            min_args = func_declr.min_args
            max_args = func_declr.max_args

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
            rest_idx = func_declr.rest_idx
            rest_position = rest_idx || func_declr.params.size

            # assign values to regular parameters (before rest parameter)
            normal_params = func_declr.normal_params
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
                if func_declr.implicit_return?
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
      # Async function call — spawns a fiber, returns an Obietnica
      # immediately, fiber body runs cooperatively under the reactor.
      #
      # Called from:
      #   - evaluate_func_call when func_declr.async is true
      #   - evaluate_method_call when calling an async instance method
      #   - ModuleFunctionCall#evaluate when calling an async module function
      #
      # The function may be a top-level async function, async method, or
      # async lambda. We accept either AST::FuncCall or AST::MethodCall as
      # `node` — they differ in whether the identifier is in `name` or
      # `method_name`, which we normalize via `call_name`.
      #
      # Crucial contract: this method must NEVER block. It schedules the
      # fiber with the reactor and returns an AS-tagged :type_instance
      # wrapping the promise. The fiber runs when the reactor gets a turn.
      #
      # Public because non-FuncCall paths (MethodCall, ModuleFunctionCall)
      # need to reach it from outside the interpreter class.
      # ====================================================================
      def evaluate_async_func_call(node, env, func_declr, func_env, instance: nil)
        reactor = AlexScript::Async::Reactor.current
        promise = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)

        # Unify naming: FuncCall has `name`, MethodCall has `method_name`.
        call_name = node.respond_to?(:name) ? node.name : node.method_name

        # Capture argument values BEFORE spawning the fiber. Arguments are
        # evaluated eagerly at the call site, in the caller's env, as they
        # are for sync calls. This matches JS/Python async semantics.
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

        fiber = Fiber.new do
          Fiber[:alex_interpreter] = self   # make interpreter reachable from native lambdas
          begin
            # Build the function's execution environment — same way the
            # sync path does. All the param binding / defaults / rest logic
            # lives in a helper for reuse.
            new_func_env = build_func_env(func_declr, func_env, arguments, node, instance: instance)

            # Track context so `czekaj` inside the body gets the right tracker
            # state. Fiber[:...] isolation means this fiber's tracker state
            # is independent of other concurrent fibers.
            result = nil
            Utils::CallStackTracker.push(:function, call_name, @current_file, node.line)
            begin
              Utils::ContextTracker.track_method_call(call_name) do
                if func_declr.implicit_return?
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

            promise.fulfill(result)
          rescue Utils::AlexScriptError => e
            promise.reject(e)
          rescue StandardError => e
            promise.reject(Utils::ExceptionsTranslator.translate(e))
          end
        end

        # Hot promise: schedule the fiber immediately. The caller gets the
        # promise RIGHT NOW, fiber runs on the next reactor tick.
        reactor.schedule_resume(fiber)

        AlexScript::Async::PromiseValue.wrap(promise, env)
      end

      # Method call — extracted from the old interpret! elsif chain.
      # Handles :type_class (static methods), :type_instance (instance methods),
      # and fallback to built-in methods for arrays/objects/primitives.
      # Called from AST::MethodCall#evaluate
      def evaluate_method_call(node, env)
        # interpret object
        object_type, object_value = interpret!(node.object, env)

        # ── Async dispatch for instance methods ──────────────────────────
        # If the resolved method is marked `asynchroniczna`, spawn a fiber
        # and return a Promise immediately. Must run BEFORE sync dispatch
        # below — otherwise the async body executes on the calling fiber
        # and `czekaj` tries to yield with no fiber to return to.
        if object_type == :type_instance
          method_result = env.find_method_in_hierarchy(object_value, node.method_name)
          if method_result
            method_info = method_result[:method_info]
            if method_info && !method_info[:native_lambda] &&
              method_info[:declaration].respond_to?(:async) && method_info[:declaration].async
              return evaluate_async_func_call(
                node, env,
                method_info[:declaration],
                method_info[:env],
                instance: object_value
              )
            end
          end
        end

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
          if env.built_in_methods.get_method(:type_class, node.method_name)
            evaluated_args = node.arguments.map { |arg| interpret!(arg, env)[1] }

            class_def[:name] ||= class_name
            evaluated_args.unshift(env) if [:przodkowie, :czy_dziedziczy_po].include?(node.method_name.to_sym)

            result = env.call_method(:type_class, node.method_name, class_def, evaluated_args)

            if result.is_a?(Array) && result.size == 2 && result[0].is_a?(Symbol)
              return result
            end

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

            # check argument count — use precomputed metadata
            func_declr = method_info[:declaration]
            rest_param = func_declr.rest_param
            min_args = func_declr.min_args
            max_args = func_declr.max_args

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
            rest_idx = func_declr.rest_idx
            rest_position = rest_idx || func_declr.params.size

            normal_params = func_declr.normal_params
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
          # ──────────────────────────────────────────────────────────────────
          # METHOD RESOLUTION ORDER for instance methods:
          #   1. User-defined methods in class hierarchy   (highest priority)
          #   2. Built-in introspection methods            (fallback)
          #
          # Rationale: this matches Ruby/Python/JS semantics — a method defined
          # in a user class always wins over a system-provided one. Built-ins
          # remain accessible only when there is no user-defined method with
          # the same name. This means a class declaring `funkcja id() { ... }`
          # gets its own id, while a class without one falls back to built-in
          # object_id-style id().
          # ──────────────────────────────────────────────────────────────────

          # ── 1. User-defined method lookup (class hierarchy) ──
          method_result = env.find_method_in_hierarchy(object_value, node.method_name)

          if method_result
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

            # check if method is private (AS-defined)
            if method_info[:private]
              current_instance = env.get_instance
              same_instance = current_instance == object_value
              from_inside_class = current_instance && current_instance[:class_name] == object_value[:class_name]
              from_subclass = current_instance && env.is_subclass_of(current_instance[:class_name], object_value[:class_name])

              unless same_instance || from_inside_class || from_subclass
                Utils.runtime_error("Próba wywołania prywatnej metody #{node.method_name}", node.line)
              end
            end

            # evaluate arguments
            arguments = node.arguments.map { |arg| interpret!(arg, env) }

            # check argument count — use precomputed metadata
            func_declr = method_info[:declaration]
            rest_param = func_declr.rest_param
            min_args = func_declr.min_args
            max_args = func_declr.max_args

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
            rest_idx = func_declr.rest_idx
            rest_position = rest_idx || func_declr.params.size

            normal_params = func_declr.normal_params
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
              result = [:type_null, Utils::NULL_VALUE]
            rescue Utils::ReturnError => e
              result = e.value
            ensure
              Utils::CallStackTracker.pop
            end

            return result
          end

          # ── 2. Built-in introspection method fallback ──
          # Reached only when no user-defined method matches. This keeps backward
          # compatibility for code that uses obj.id / obj.typ / etc. on classes
          # that don't define their own — but never shadows user methods.
          if env.built_in_methods.get_method(:type_instance, node.method_name)
            evaluated_args = node.arguments.map { |arg| interpret!(arg, env)[1] }
            result = env.call_method(:type_instance, node.method_name, object_value, evaluated_args)

            # Built-in already returned a tagged tuple — pass through
            if result.is_a?(Array) && result.size == 2 && result[0].is_a?(Symbol)
              return result
            end

            # Convert raw Ruby value to AS-tagged tuple
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

          # Neither user-defined nor built-in — genuine missing method.
          Utils.runtime_error(
            "Nieznana metoda #{node.method_name} dla instancji klasy #{object_value[:class_name]}",
            node.line
          )

        elsif object_type == :type_module
          module_def = object_value
          module_name = module_def[:name]

          # 1. User-defined function — delegate via ModuleFunctionCall
          module_func = env.get_module_function([module_name], node.method_name)
          if module_func
            synthetic = AST::ModuleFunctionCall.new(
              [module_name], node.method_name, node.arguments, node.line
            )
            return interpret!(synthetic, env)
          end

          # 2. Class in module — return class_def. Only for parameterless access (no args),
          #    because Mojmodul.Klasa(args) is not a valid construct (use Mojmodul::Klasa.nowy()).
          if node.arguments.empty?
            class_in_module = env.get_module_class([module_name], node.method_name)
            if class_in_module
              class_in_module[:name] ||= node.method_name
              return [:type_class, class_in_module]
            end

            # 3. Constant in module
            constant = module_def[:constants] && module_def[:constants][node.method_name]
            if constant
              return [constant[:type], constant[:value]]
            end
          end

          # 4. Built-in module reflection method
          if env.built_in_methods.get_method(:type_module, node.method_name)
            evaluated_args = node.arguments.map { |arg| interpret!(arg, env)[1] }
            result = env.call_method(:type_module, node.method_name, module_def, evaluated_args)

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
          end

          Utils.runtime_error("Nieznana metoda '#{node.method_name}' dla modułu #{module_name}",node.line)
        else
          # ── Non-instance types: arrays, floats, ints, strings, objects, bools, null ──
          # Reached when object_type is :type_array, :type_int, :type_float,
          # :type_string, :type_bool, :type_object, :type_null. These types
          # have built-in methods registered globally and don't have user-defined classes.
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

      # Peek at where a FuncCall resolves, without executing it. Returns
      # a hash { func_declr:, func_env:, instance: } or nil if nothing
      # matches (sync path will handle the error).
      #
      # Used by evaluate_func_call to detect async-ness before spawning
      # fibers. Mirrors the lookup logic in the sync path closely — if the
      # two ever drift, async detection will silently miss cases. TODO:
      # factor out lookup when refactoring evaluate_func_call proper.
      def resolve_func_for_async_check(node, env)
        # Fast path for the most common case (top-level functions like `fib`):
        # try the function registry first, before any instance/variable walks.
        # If it's not async, we return nil to skip async dispatch — the sync
        # path will do its own resolution anyway.
        func = env.get_func(node.name)
        if func
          declr = func[0]
          return nil unless declr.async  # not async → skip async dispatch entirely
          return { func_declr: declr, func_env: func[1], instance: nil }
        end

        # Instance method (only if we're in a class context — rare in hot loops).
        current_instance = env.get_instance
        if current_instance
          class_name = current_instance[:class_name]
          while class_name
            class_def =
              if current_instance[:module_path] && !current_instance[:module_path].empty?
                env.get_module_class(current_instance[:module_path], class_name)
              else
                env.get_class(class_name)
              end
            break unless class_def

            method = class_def[:methods] && class_def[:methods][node.name]
            if method && !method[:native_lambda]
              declr = method[:declaration]
              return nil unless declr.async  # same: skip if not async
              return {
                func_declr: declr,
                func_env:   method[:env],
                instance:   current_instance
              }
            end

            class_name = class_def[:parent]
          end
        end

        # Variable holding a function value (rare in hot loops).
        var = env.get_var(node.name)
        if var && var[:type] == :type_function && var[:value][:declaration]
          declr = var[:value][:declaration]
          return nil unless declr.async  # same
          return {
            func_declr: declr,
            func_env:   var[:value][:env],
            instance:   nil
          }
        end

        nil
      end

      # ── Entry points — sync vs async-aware ──────────────────────────────
      #
      # interpret_ast is the historical public entry point. It runs a program
      # to completion and raises on unhandled errors — this is what alexscript.rb,
      # the REPL, and the import manager all call.
      #
      # interpret_node_with_translation is the reusable primitive: it executes
      # a node, translates Ruby-native StandardError into AlexScriptError, and
      # re-raises. Both sync and (future) async pathways share it; only the
      # rescue-handling policy differs.
      #
      # The separation exists to prepare for async:
      #   - sync mode  → unhandled exceptions kill the program (current behavior)
      #   - async mode → unhandled exceptions reject the fiber's Obietnica,
      #                  leaving other fibers (and the interpreter) alive.
      #
      # The async pathway lives in Core::AsyncInterpreter and calls this same
      # primitive method, just wrapping the raise in promise.odrzuc(e) instead.

      def interpret_ast(node, env = nil)
        environment = env || Environment.new
        Fiber[:alex_interpreter] ||= self
        interpret_node_with_translation(node, environment)
      end

      # Runs a node and translates any Ruby-native StandardError into an
      # AlexScriptError before re-raising. AlexScriptError itself passes
      # through unchanged.
      #
      # Public so that AsyncInterpreter (and any future pathway that needs
      # translated-but-not-caught exceptions) can call it.
      def interpret_node_with_translation(node, env)
        interpret!(node, env)
      rescue Utils::AlexScriptError => e
        raise e
      rescue StandardError => e
        # translate and re-raise
        alex_error = Utils::ExceptionsTranslator.translate(e)
        raise alex_error
      end

      # ════════════════════════════════════════════════════════════════════
      # PRIVATE helpers
      # ════════════════════════════════════════════════════════════════════
      private

      # Helper extracted from evaluate_func_call's sync body — binds
      # arguments to parameters (including defaults and rest), produces
      # the inner env ready to execute the function body.
      #
      # Shared between async paths only (sync path in evaluate_func_call
      # still has its own inlined copy — we didn't want to touch it in
      # this patch). Called from evaluate_async_func_call.
      #
      # Handles both FuncCall (has `name`) and MethodCall (has `method_name`)
      # node types, unified via `call_name`.
      def build_func_env(func_declr, func_env, arguments, node, instance: nil)
        call_name = node.respond_to?(:name) ? node.name : node.method_name

        rest_param = func_declr.rest_param
        min_args = func_declr.min_args
        max_args = func_declr.max_args

        if arguments.size < min_args
          Utils.runtime_error(
            "Funkcja #{call_name} oczekiwala minimum #{min_args} argumentow, otrzymala #{arguments.size}",
            node.line
          )
        end

        unless rest_param
          if arguments.size > max_args
            Utils.runtime_error(
              "Funkcja #{call_name} oczekiwala maksymalnie #{max_args} argumentow, otrzymala #{arguments.size}",
              node.line
            )
          end
        end

        new_func_env = func_env.new_env
        new_func_env.set_instance(instance) if instance

        rest_idx = func_declr.rest_idx
        rest_position = rest_idx || func_declr.params.size

        normal_params = func_declr.normal_params
        normal_params.each_with_index do |param, idx|
          if idx < arguments.size && (rest_idx.nil? || idx < rest_idx)
            arg_val = arguments[idx]
            new_func_env.set_local_var(param.name, arg_val[1], arg_val[0])
          elsif param.has_default?
            default_value = interpret!(param.default_value, func_env)
            new_func_env.set_local_var(param.name, default_value[1], default_value[0])
          else
            Utils.runtime_error("Brakujacy argument #{param.name}", node.line)
          end
        end

        if rest_param
          rest_args = arguments[rest_position..-1] || []
          rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
          new_func_env.set_local_var(rest_param.name, rest_array_elements, :type_array)
        end

        new_func_env
      end
    end
  end
end