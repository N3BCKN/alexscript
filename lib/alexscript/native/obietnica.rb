# frozen_string_literal: true

require_relative '../async/async'

module AlexScript
  module Native
    # ============================================================
    # Obietnica — AlexScript-facing class wrapping ObietnicaImpl.
    #
    # Registered as a native class (same pattern as Czas, Mat, Socket).
    # The underlying ObietnicaImpl instance lives in :__native__; all
    # methods dispatch through the native_lambda mechanism.
    #
    # User-facing API:
    #   Instance methods:
    #     .stan()     → "oczekuje" | "spelniona" | "odrzucona"
    #     .wartosc()  → fulfilled value (error if not fulfilled)
    #     .powod()    → rejection reason (error if not rejected)
    #
    #   Static methods:
    #     Obietnica.spelniona(wartosc)  → new fulfilled Obietnica
    #     Obietnica.odrzucona(powod)    → new rejected Obietnica
    #
    # NOT in MVP (comes later alongside Fiber::Scheduler work):
    #     Obietnica.wszystkie / .dowolna / .limit_czasu
    #     .potem() / .zlap() / .zakoncz()
    #     Obietnica.nowa(fn(spelnij, odrzuc) { ... })
    # ============================================================
    module ObietnicaLibrary
      module_function

      STATE_LABEL = {
        AlexScript::Async::ObietnicaImpl::STATE_PENDING   => 'oczekuje',
        AlexScript::Async::ObietnicaImpl::STATE_FULFILLED => 'spelniona',
        AlexScript::Async::ObietnicaImpl::STATE_REJECTED  => 'odrzucona'
      }.freeze

      def register!
        Utils::NativeClassRegistry.define_class(
          'Obietnica',

          # Constructor: Obietnica.nowa(wartosc_or_nil)
          # MVP: the no-arg form creates a pending promise, useful mostly
          # for tests. The executor-style `Obietnica.nowa(fn(spelnij,
          # odrzuc) { ... })` is post-MVP — require_once explicit and we
          # raise a clear error if called that way.
          constructor: ->(*args) {
            reactor = AlexScript::Async::Reactor.current

            if args.empty?
              # Bare constructor — pending promise, settle externally.
              next AlexScript::Async::ObietnicaImpl.new(reactor: reactor)
            end

            # Executor-style: single function argument invoked synchronously
            # with (spelnij, odrzuc) callbacks. The user's AS code inside the
            # executor calls spelnij(value) or odrzuc(reason) to settle.
            #
            # The executor is an AS function value, so we need the interpreter
            # to invoke it. We pull the interpreter from the fiber-local
            # storage populated at the start of every async fiber body.
            #
            # Non-async context (calling Obietnica.nowa from top-level sync code)
            # is also supported: the root process's :alex_interpreter is set by
            # `uruchom` when it enters run_until. If absent, we raise — calling
            # Obietnica.nowa(executor) without a live interpreter makes no sense.
            raise 'Obietnica.nowa oczekuje 1 argumentu (funkcji executor)' if args.size != 1

            executor = args[0]
            # After NativeTypeConverter.to_ruby, an AS :type_function value
            # becomes the inner hash (:declaration, :env). We accept either:
            # - the hash directly (from to_ruby on :type_function)
            # - or already-extracted form. Check by presence of :declaration.
            unless executor.is_a?(Hash) && executor[:declaration]
              raise 'Obietnica.nowa oczekuje funkcji jako argumentu'
            end

            promise = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)

            # Build resolve/reject as AS-callable native functions.
            spelnij = AlexScript::Async::PromiseValue.build_native_function('spelnij', ->(as_value = nil) {
              # as_value is an AS tuple [type, value]; promise stores it verbatim.
              # fulfill is a no-op if already settled, which matches JS semantics.
              promise.fulfill(as_value)
              [:type_null, AlexScript::Utils::NULL_VALUE]
            })

            odrzuc = AlexScript::Async::PromiseValue.build_native_function('odrzuc', ->(as_reason = nil) {
              # Reject reason can be anything — an AS instance (exception), a string, etc.
              # Convert AS tuple back to something useful for the reject path:
              # if it's a :type_instance of an exception, unwrap; else wrap string.
              reason = if as_reason.is_a?(Array) && as_reason.size == 2
                        type_sym, val = as_reason
                        if type_sym == :type_instance && val.is_a?(Hash) && val[:instance_vars]
                          # AS exception instance. Reconstruct AlexScriptError from it.
                          class_name = val[:class_name]
                          message = val[:instance_vars]['wiadomosc']&.last || class_name
                          AlexScript::Utils::AlexScriptError.new(class_name, message)
                        elsif type_sym == :type_string
                          AlexScript::Utils::AlexScriptError.new('BladWykonania', val.to_s)
                        else
                          AlexScript::Utils::AlexScriptError.new('BladWykonania', val.to_s)
                        end
                      else
                        AlexScript::Utils::AlexScriptError.new('BladWykonania', as_reason.to_s)
                      end
              promise.reject(reason)
              [:type_null, AlexScript::Utils::NULL_VALUE]
            })

            # Invoke the executor synchronously. We need an interpreter to
            # dispatch AS function calls — pull it from fiber-local storage.
            interpreter = Fiber[:alex_interpreter]
            raise 'Obietnica.nowa wymaga aktywnego interpretera (uzyj wewnatrz asynchronicznej funkcji lub pod uruchom)' unless interpreter

            # Synthesize a LambdaCall that calls the executor with (spelnij, odrzuc).
            # We stage the arguments in the env as temporaries so LambdaCall can
            # resolve them via Identifier lookup.
            executor_env = executor[:env] || interpreter.instance_variable_get(:@_root_env) || AlexScript::Core::Environment.new

            # Actually: simpler — construct synthetic AST with argument *values*
            # bypassing identifier resolution. We can reuse executor's internal
            # mechanism by wrapping each arg in a zero-line placeholder node.

            # The cleanest approach: interpret the executor's body directly with
            # pre-bound parameters. We don't have a clean "call function with
            # pre-evaluated args" API, so the most reliable path is to synthesize
            # a FuncCall through the interpreter — but FuncCall needs a name
            # in scope. Variable binding in a temp env is the least-friction solution.

            call_env = executor_env.new_env
            call_env.set_local_var('__alex_executor__', executor, :type_function)
            call_env.set_local_var('__alex_spelnij__', spelnij[1], :type_function)
            call_env.set_local_var('__alex_odrzuc__',  odrzuc[1],  :type_function)

            synthetic_call = AlexScript::AST::LambdaCall.new(
              AlexScript::AST::Identifier.new('__alex_executor__', 0),
              [
                AlexScript::AST::Identifier.new('__alex_spelnij__', 0),
                AlexScript::AST::Identifier.new('__alex_odrzuc__',  0)
              ],
              0
            )

            begin
              interpreter.interpret!(synthetic_call, call_env)
            rescue AlexScript::Utils::AlexScriptError => e
              # Executor threw — reject the promise with the exception (unless
              # it was already settled; fulfill/reject are idempotent).
              promise.reject(e)
            rescue StandardError => e
              promise.reject(AlexScript::Utils::ExceptionsTranslator.translate(e))
            end

            # Return the ObietnicaImpl — NativeClassRegistry dispatch_constructor
            # will wrap it in a :type_instance.
            next promise
          },

          methods: {
            'stan' => ->(promise_impl) { STATE_LABEL.fetch(promise_impl.state) },

            'wartosc' => ->(promise_impl) {
              unless promise_impl.fulfilled?
                raise "Obietnica nie jest spelniona (stan: #{STATE_LABEL.fetch(promise_impl.state)})"
              end
              stored = promise_impl.value
              # Async fibers (from `asynchroniczna funkcja`) store tagged tuples
              # [type, value]. User-facing Obietnica.spelniona(v) stores the raw
              # Ruby value. Detect which shape we have and return the Ruby value
              # so native dispatch can re-tag it uniformly.
              if stored.is_a?(Array) && stored.size == 2 && stored[0].is_a?(Symbol) && stored[0].to_s.start_with?('type_')
                stored[1]
              else
                stored
              end
            },

            'powod' => ->(promise_impl) {
              unless promise_impl.rejected?
                raise "Obietnica nie jest odrzucona (stan: #{STATE_LABEL.fetch(promise_impl.state)})"
              end
              reason = promise_impl.reason
              reason.is_a?(Utils::AlexScriptError) ? reason.message : reason.to_s
            }
          },

          static_methods: {
            'spelniona' => ->(wartosc) {
              p = AlexScript::Async::ObietnicaImpl.new(reactor: AlexScript::Async::Reactor.current)
              p.fulfill(wartosc)
              instance = {
                class_name: 'Obietnica',
                instance_vars: {},
                class_def: Utils::NativeClassRegistry.get_class_def('Obietnica'),
                __native__: p
              }
              [:type_instance, instance]
            },

            'odrzucona' => ->(powod) {
              p = AlexScript::Async::ObietnicaImpl.new(reactor: AlexScript::Async::Reactor.current)
              reason = powod.is_a?(Utils::AlexScriptError) ? powod : Utils::AlexScriptError.new('BladWykonania', powod.to_s)
              p.reject(reason)
              instance = {
                class_name: 'Obietnica',
                instance_vars: {},
                class_def: Utils::NativeClassRegistry.get_class_def('Obietnica'),
                __native__: p
              }
              [:type_instance, instance]
            },   
            
              # ────────────────────────────────────────────────────────────────
              # Obietnica.wszystkie(tablica) → Obietnica<tablica_wartosci>
              #
              # Waits for all input promises to fulfill. Resolves with an array
              # of their values in original order. Rejects with the first
              # rejection if any input rejects (fail-fast, JS Promise.all semantics).
              #
              # An empty input array resolves immediately with []. Non-promise
              # values in the array are treated as Obietnica.spelniona(v).
              # ────────────────────────────────────────────────────────────────
              'wszystkie' => ->(tablica) {
                reactor = AlexScript::Async::Reactor.current
                aggregate = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)

                # The input from AS-side is a Ruby Array of already-converted
                # values (NativeTypeConverter.to_ruby unwraps the tagged tuples).
                # Native instances come through as their :__native__ objects —
                # meaning an AS array of Obietnica instances arrives here as a
                # Ruby array of ObietnicaImpl objects. Clean.
                inputs = Array(tablica)

                if inputs.empty?
                  aggregate.fulfill([:type_array, []])
                  next AlexScript::Async::PromiseValue.wrap_from_registry(aggregate)
                end

                results = Array.new(inputs.size)
                pending_count = inputs.size
                already_rejected = false

                inputs.each_with_index do |item, idx|
                  # Coerce non-promises to fulfilled promises (sugar, matches czekaj).
                  promise = if item.is_a?(AlexScript::Async::ObietnicaImpl)
                              item
                            else
                              p = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)
                              p.fulfill(item)
                              p
                            end

                  promise.on_settle do |settled|
                    next if already_rejected

                    if settled.fulfilled?
                      # Store in original index. Value may be a tagged tuple (from
                      # an async fiber) or a raw Ruby value (from Obietnica.spelniona).
                      # We keep it as-is and unwrap once at the end.
                      results[idx] = settled.value
                      pending_count -= 1
                      if pending_count.zero?
                        # Build final AS array: elements must be {type:, value:} hashes.
                        elements = results.map do |v|
                          t, val = unwrap_tagged_or_infer(v)
                          { type: t, value: val }
                        end
                        aggregate.fulfill([:type_array, elements])
                      end
                    else
                      already_rejected = true
                      aggregate.reject(settled.reason)
                    end
                  end
                end

                AlexScript::Async::PromiseValue.wrap_from_registry(aggregate)
              },

              # ────────────────────────────────────────────────────────────────
              # Obietnica.dowolna(tablica) → Obietnica<wartosc>
              #
              # Resolves with the value of the first input to fulfill. If all
              # inputs reject, the aggregate rejects with the LAST rejection
              # reason (simplified from JS Promise.any which uses AggregateError).
              #
              # Empty input → immediate rejection (no candidate can ever win).
              # ────────────────────────────────────────────────────────────────
              'dowolna' => ->(tablica) {
                reactor = AlexScript::Async::Reactor.current
                aggregate = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)

                inputs = Array(tablica)

                if inputs.empty?
                  aggregate.reject(Utils::AlexScriptError.new('BladWykonania',
                    'Obietnica.dowolna wymaga niepustej tablicy'))
                  next AlexScript::Async::PromiseValue.wrap_from_registry(aggregate)
                end

                already_fulfilled = false
                rejection_count = 0
                last_reason = nil

                inputs.each do |item|
                  promise = if item.is_a?(AlexScript::Async::ObietnicaImpl)
                              item
                            else
                              p = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)
                              p.fulfill(item)
                              p
                            end

                  promise.on_settle do |settled|
                    next if already_fulfilled

                    if settled.fulfilled?
                      already_fulfilled = true
                      aggregate.fulfill(settled.value)
                    else
                      rejection_count += 1
                      last_reason = settled.reason
                      if rejection_count == inputs.size
                        aggregate.reject(last_reason)
                      end
                    end
                  end
                end

                AlexScript::Async::PromiseValue.wrap_from_registry(aggregate)
              },

              # ────────────────────────────────────────────────────────────────
              # Obietnica.limit_czasu(obietnica, ms) → Obietnica
              #
              # Races the input promise against a timer. Resolves with the input's
              # value if it settles before the timeout, otherwise rejects with
              # BladLimituCzasu. If the input rejects before timeout, that
              # rejection propagates (timer is cancelled by first-settle logic).
              # ────────────────────────────────────────────────────────────────
              'limit_czasu' => ->(obietnica, ms) {
                reactor = AlexScript::Async::Reactor.current
                wrapper = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)

                inner = if obietnica.is_a?(AlexScript::Async::ObietnicaImpl)
                          obietnica
                        else
                          # Non-promise input: treat as already-fulfilled. Timeout
                          # still applies nominally but will never fire since
                          # on_settle triggers immediately on already-settled.
                          p = AlexScript::Async::ObietnicaImpl.new(reactor: reactor)
                          p.fulfill(obietnica)
                          p
                        end

                settled = false

                inner.on_settle do |s|
                  next if settled
                  settled = true
                  if s.fulfilled?
                    wrapper.fulfill(s.value)
                  else
                    wrapper.reject(s.reason)
                  end
                end

                reactor.schedule_timer(ms) do
                  next if settled
                  settled = true
                  wrapper.reject(Utils::AlexScriptError.new('BladLimituCzasu',
                    "Przekroczono limit czasu #{ms}ms"))
                end

                AlexScript::Async::PromiseValue.wrap_from_registry(wrapper)
              }
          }
        )
      end

      # Given a value that could be either a tagged tuple [type, value]
      # (from an async fiber) or a raw Ruby value (from Obietnica.spelniona
      # or non-promise input), return [type, value] suitably tagged.
      def unwrap_tagged_or_infer(v)
        if v.is_a?(Array) && v.size == 2 && v[0].is_a?(Symbol) && v[0].to_s.start_with?('type_')
          v
        else
          [infer_as_type(v), v]
        end
      end

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