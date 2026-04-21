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
            }
          }
        )
      end
    end
  end
end