# frozen_string_literal: true

module AlexScript
  module Async
    # ============================================================
    # PromiseValue — bridge between ObietnicaImpl and AlexScript's
    # tagged-tuple value representation.
    #
    # AlexScript represents every value as [type_symbol, ruby_value].
    # Native class instances live in :type_instance with a hash holding
    # :class_name, :instance_vars, :class_def, and optionally :__native__
    # for the underlying Ruby object.
    #
    # This module centralizes the wrapping/unwrapping logic so that
    # interpreter, AwaitExpr, built-ins (uruchom/uspij/uruchom_rownolegle),
    # and the Obietnica class methods all agree on the shape.
    # ============================================================
    module PromiseValue
      module_function

      # Wrap a raw ObietnicaImpl into an AlexScript :type_instance value.
      # The class_def is looked up from the given environment — every env
      # must have access to Obietnica because we register it at startup.
      def wrap(promise_impl, env)
        class_def = env.get_class('Obietnica')
        raise 'Obietnica class not registered — load order issue' unless class_def

        instance = {
          class_name: 'Obietnica',
          instance_vars: {},
          class_def: class_def,
          __native__: promise_impl
        }

        [:type_instance, instance]
      end
      
      # Extract the ObietnicaImpl from an AS value.
      # Returns nil if the value is not a promise instance — caller decides
      # whether that's an error. We don't raise here; callers have more
      # context for a good error message.
      def unwrap(type, value)
        return nil unless type == :type_instance
        return nil unless value.is_a?(Hash)
        return nil unless value[:class_name] == 'Obietnica'
        value[:__native__]
      end

      # Wrap a raw ObietnicaImpl into an AS value without an env at hand.
      # Used from native static method lambdas where only the registry is
      # accessible. Equivalent to wrap() but reads the class_def from the
      # registry directly.
      def wrap_from_registry(promise_impl)
        class_def = Utils::NativeClassRegistry.get_class_def('Obietnica')
        raise 'Obietnica class not registered' unless class_def

        instance = {
          class_name: 'Obietnica',
          instance_vars: {},
          class_def: class_def,
          __native__: promise_impl
        }

        [:type_instance, instance]
      end

      # Convenience predicate.
      def promise?(type, value)
        !unwrap(type, value).nil?
      end
    end
  end
end