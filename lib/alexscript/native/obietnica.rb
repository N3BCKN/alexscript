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
            if args.empty?
              AlexScript::Async::ObietnicaImpl.new(reactor: AlexScript::Async::Reactor.current)
            else
              raise 'Konstruktor Obietnica.nowa() z argumentem nie jest wspierany w tej wersji. ' \
                    'Uzyj Obietnica.spelniona(wartosc) lub Obietnica.odrzucona(powod).'
            end
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