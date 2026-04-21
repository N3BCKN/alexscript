# frozen_string_literal: true

module AlexScript
  module Async
    # ============================================================
    # Built-in async functions — uruchom, uspij, uruchom_rownolegle.
    #
    # These are NOT Ruby-visible functions; they're intercepted in
    # evaluate_func_call before regular function resolution. The names
    # act like reserved built-ins, similar to pokazl/pokaz except the
    # parser doesn't special-case them — they look like ordinary
    # FuncCall nodes and are intercepted at evaluation time.
    #
    # That's intentional: it lets `uruchom(cos)` parse using the same
    # grammar as any other call, and lets higher-level code (e.g. a
    # future `oprocz uruchom zwroc ...`) work naturally.
    # ============================================================
    module Builtins
      BUILTIN_NAMES = %w[uruchom uspij uruchom_rownolegle].freeze

      module_function

      def builtin?(name)
        BUILTIN_NAMES.include?(name)
      end

      def dispatch(name, node, env, interpreter)
        case name
        when 'uruchom'              then call_uruchom(node, env, interpreter)
        when 'uspij'                then call_uspij(node, env, interpreter)
        when 'uruchom_rownolegle'   then call_uruchom_rownolegle(node, env, interpreter)
        else
          Utils.runtime_error("Nieznany wbudowany async: #{name}", node.line)
        end
      end

      # --------------------------------------------------------------
      # uruchom(arg)
      #   - arg is a Promise → wait until it settles, return its value
      #   - arg is an async function value → call it (no args), then
      #     wait on the resulting promise
      #
      # Enters the reactor loop. BLOCKS the calling thread until the
      # promise settles. Typically called from top-level sync code as
      # the entry point into the async world.
      # --------------------------------------------------------------
      def call_uruchom(node, env, interpreter)
        Fiber[:alex_interpreter] = interpreter
        if node.arguments.size != 1
          Utils.runtime_error(
            "uruchom oczekuje 1 argumentu, otrzymalo #{node.arguments.size}",
            node.line
          )
        end

        arg_type, arg_value = interpreter.interpret!(node.arguments[0], env)

        promise_impl = PromiseValue.unwrap(arg_type, arg_value)

        if promise_impl.nil?
          # Maybe it's an async function value — synthesize a FuncCall
          # to invoke it, and expect a promise back.
          if arg_type == :type_function && arg_value[:declaration].respond_to?(:async) && arg_value[:declaration].async
            synthetic_call = AST::FuncCall.new(
              arg_value[:declaration].name, [], node.line
            )
            result_type, result_value = interpreter.interpret!(synthetic_call, env)
            promise_impl = PromiseValue.unwrap(result_type, result_value)
          end
        end

        if promise_impl.nil?
          Utils.runtime_error(
            'uruchom oczekuje Obietnicy lub funkcji asynchronicznej',
            node.line
          )
        end

        reactor = Reactor.current
        result = reactor.run_until(promise_impl)

        # Unwrap tagged tuple or infer type for raw values.
        if result.is_a?(Array) && result.size == 2 && result[0].is_a?(Symbol) && result[0].to_s.start_with?('type_')
          result
        else
          [infer_as_type(result), result]
        end
      end

      # --------------------------------------------------------------
      # uspij(ms) → Obietnica
      # Returns a promise that fulfills with `nic` after `ms`.
      # Typically used as `czekaj uspij(100)`.
      # --------------------------------------------------------------
      def call_uspij(node, env, interpreter)
        if node.arguments.size != 1
          Utils.runtime_error(
            "uspij oczekuje 1 argumentu (liczba ms), otrzymalo #{node.arguments.size}",
            node.line
          )
        end

        ms_type, ms_value = interpreter.interpret!(node.arguments[0], env)
        unless %i[type_int type_float].include?(ms_type)
          Utils.runtime_error(
            "uspij oczekuje liczby (ms), otrzymalo #{ms_type}",
            node.line
          )
        end

        reactor = Reactor.current
        promise = ObietnicaImpl.new(reactor: reactor)
        reactor.schedule_timer(ms_value) do
          promise.fulfill([:type_null, Utils::NULL_VALUE])
        end

        PromiseValue.wrap(promise, env)
      end

      # --------------------------------------------------------------
      # uruchom_rownolegle(fn) → Obietnica
      # Fire-and-forget spawn of a function as a fiber. Returns a
      # promise for its result. Function may be async or sync — both
      # work; sync function returns immediately fulfilled.
      # --------------------------------------------------------------
      def call_uruchom_rownolegle(node, env, interpreter)
        if node.arguments.size != 1
          Utils.runtime_error(
            "uruchom_rownolegle oczekuje 1 argumentu (funkcja), otrzymalo #{node.arguments.size}",
            node.line
          )
        end

        fn_type, fn_value = interpreter.interpret!(node.arguments[0], env)
        unless fn_type == :type_function
          Utils.runtime_error('uruchom_rownolegle oczekuje funkcji', node.line)
        end

        reactor = Reactor.current
        promise = ObietnicaImpl.new(reactor: reactor)

        # Capture the function value at spawn time; fiber body invokes it
        # via a synthesized LambdaCall whose callee evaluates to the same
        # function. We use AST::Identifier with a unique temp binding — but
        # simpler: wrap the already-evaluated function into a trivial expr
        # that just re-yields it.
        #
        # The cleanest way: construct a LambdaCall whose `callee` is a node
        # that evaluates back to [fn_type, fn_value]. We use a small shim
        # node-style container, or — the simpler path — bind the function
        # to a temp variable in the env and reference it.

        temp_name = "__alex_bg_fn_#{fn_value.object_id}__"
        env.set_local_var(temp_name, fn_value, :type_function)
        synthetic_call = AST::LambdaCall.new(
          AST::Identifier.new(temp_name, node.line),
          [],
          node.line
        )

        fiber = Fiber.new do
          Fiber[:alex_interpreter] = interpreter # make interpreter reachable from native lambdas
          begin
            result = interpreter.interpret!(synthetic_call, env)
            promise.fulfill(result)
          rescue Utils::AlexScriptError => e
            promise.reject(e)
          rescue StandardError => e
            promise.reject(Utils::ExceptionsTranslator.translate(e))
          end
        end

        reactor.schedule_resume(fiber)

        PromiseValue.wrap(promise, env)
      end

      # --------------------------------------------------------------
      # Private helper
      # --------------------------------------------------------------
      def infer_as_type(value)
        case value
        when Integer then :type_int
        when Float then :type_float
        when String then :type_string
        when TrueClass, FalseClass then :type_bool
        when NilClass then :type_null
        when Array then :type_array
        when Hash then :type_object
        else :type_object
        end
      end
    end
  end
end