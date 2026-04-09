# frozen_string_literal: true

# lib/alexscript/utils/native_class_registry.rb
#
# Central registry for native (Ruby-backed) AlexScript classes.
# Native classes bypass AST interpretation entirely — their methods
# are Ruby lambdas called directly by the interpreter, giving 5-10x
# speedup over the old ruby()/ruby_obj() bridge.
#
# Architecture:
#   NativeClassRegistry — singleton registry + dispatch
#   NativeTypeConverter — AS<->Ruby type conversion (zero allocation for common cases)
#
# A native class looks like a normal class_def hash to the interpreter,
# with an extra :native flag and lambda hashes instead of AST declarations.
#
# Instance layout:
#   { class_name: 'Czas', instance_vars: {}, class_def: ..., __native__: <Ruby obj> }
#   The __native__ key is a direct field (not inside instance_vars) for
#   single-lookup performance on every method call.

module AlexScript
  module Utils
    # ─── Type Converter ────────────────────────────────────────────
    # Stateless, no allocations for primitives.
    module NativeTypeConverter
      # Convert AS [type, value] → Ruby value
      # Hot path: called once per argument on every native method call.
      def self.to_ruby(type, value)
        case type
        when :type_int, :type_float
          value
        when :type_string
          value.to_s
        when :type_bool
          value.is_a?(PrimitiveValue) ? value.truthy? : (value == true)
        when :type_null
          nil
        when :type_instance
          # Extract the wrapped Ruby object if this is a native instance
          value[:__native__] || value
        when :type_array
          value.map { |elem| to_ruby(elem[:type], elem[:value]) }
        when :type_object
          h = {}
          value.each { |k, v| h[k] = to_ruby(v[:type], v[:value]) }
          h
        else
          value
        end
      end

      # Convert Ruby value → AS [type, value]
      # Used for return values from native methods.
      def self.from_ruby(value)
        case value
        when Integer  then [:type_int, value]
        when Float    then [:type_float, value]
        when String   then [:type_string, value]
        when true     then [:type_bool, BOOL_TRUE]
        when false    then [:type_bool, BOOL_FALSE]
        when nil      then [:type_null, NULL_VALUE]
        when Symbol   then [:type_string, value.to_s]
        when Array
          elements = value.map do |v|
            r = from_ruby(v)
            { type: r[0], value: r[1] }
          end
          [:type_array, elements]
        when Hash
          pairs = {}
          value.each do |k, v|
            r = from_ruby(v)
            pairs[k.to_s] = { type: r[0], value: r[1] }
          end
          [:type_object, pairs]
        else
          [:type_string, value.to_s]
        end
      end
    end

    # ─── Native Class Registry ─────────────────────────────────────
    class NativeClassRegistry
      # Class-level state (singleton pattern matching CallStackTracker etc.)
      @classes = {}          # AS class name => class_info hash
      @ruby_class_map = {}   # Ruby class => AS class name (for auto-wrapping returns)
      @class_defs = {}       # AS class name => pre-built class_def (cached)
      @libraries = {}        # library name => loader proc

      class << self
        # ── Class Registration ──────────────────────────────────

        # Define a native class.
        #
        # @param name [String] AlexScript class name (e.g. 'Czas')
        # @param ruby_class [Class, nil] Ruby class for auto-wrapping returns
        # @param constructor [Proc] called with Ruby-converted args, returns Ruby object
        # @param methods [Hash<String, Proc>] instance methods: name => lambda(native_obj, *args)
        # @param static_methods [Hash<String, Proc>] class methods: name => lambda(*args)
        # @param static_vars [Hash<String, Object>] class constants: name => Ruby value
        # @param parent [String, nil] parent class name for inheritance
        def define_class(name, ruby_class: nil, constructor:, methods: {},
                         static_methods: {}, static_vars: {}, parent: nil)
          class_info = {
            name: name,
            ruby_class: ruby_class,
            constructor: constructor,
            methods: methods,
            static_methods: static_methods,
            static_vars: static_vars,
            parent: parent
          }.freeze

          @classes[name] = class_info
          @ruby_class_map[ruby_class] = name if ruby_class

          # Pre-build and cache the interpreter-compatible class_def
          @class_defs[name] = build_class_def(class_info)

          class_info
        end

        # Check if a class is registered
        def registered?(name)
          @classes.key?(name)
        end

        # Get class info
        def get(name)
          @classes[name]
        end

        # Get pre-built class_def (interpreter-compatible)
        def get_class_def(name)
          @class_defs[name]
        end

        # ── Library Registration ────────────────────────────────

        # Register a native library loader.
        # @param name [String] library name used in importuj("name")
        # @param block [Proc] called with (env) to register classes
        def register_library(name, &block)
          @libraries[name] = block
        end

        # Check if a library name is a native library
        def native_library?(name)
          @libraries.key?(name)
        end

        # Load a native library into an environment
        def load_library(name, env)
          loader = @libraries[name]
          return false unless loader
          loader.call(env)
          true
        end

        # Register a native class into an AS Environment
        def register_into_env(name, env)
          class_def = @class_defs[name]
          return false unless class_def
          env.define_class(name, class_def)
          true
        end

        # ── Dispatch ────────────────────────────────────────────
        # These are the hot paths called by the interpreter.

        # Dispatch native constructor. Returns the raw Ruby object.
        def dispatch_constructor(class_name, as_args)
          class_info = @classes[class_name]

          if as_args.empty?
            class_info[:constructor].call
          else
            ruby_args = as_args.map { |a| NativeTypeConverter.to_ruby(a[0], a[1]) }
            class_info[:constructor].call(*ruby_args)
          end
        end

        # Dispatch native instance method. Returns AS [type, value].
        def dispatch_instance_method(instance, method_name, as_args)
          native_obj = instance[:__native__]
          class_info = @classes[instance[:class_name]]
          lambda_fn = class_info[:methods][method_name]

          # Fast path for zero-arg methods (getters) — no array allocation
          if as_args.empty?
            result = lambda_fn.call(native_obj)
          else
            ruby_args = as_args.map { |a| NativeTypeConverter.to_ruby(a[0], a[1]) }
            result = lambda_fn.call(native_obj, *ruby_args)
          end

          convert_return(result)
        end

        # Dispatch native static method. Returns AS [type, value].
        def dispatch_static_method(class_name, method_name, as_args)
          class_info = @classes[class_name]
          lambda_fn = class_info[:static_methods][method_name]

          if as_args.empty?
            result = lambda_fn.call
          else
            ruby_args = as_args.map { |a| NativeTypeConverter.to_ruby(a[0], a[1]) }
            result = lambda_fn.call(*ruby_args)
          end

          convert_return(result)
        end

        # Check if a native class has a given instance method
        def has_instance_method?(class_name, method_name)
          info = @classes[class_name]
          info && info[:methods].key?(method_name)
        end

        # Check if a native class has a given static method
        def has_static_method?(class_name, method_name)
          info = @classes[class_name]
          info && info[:static_methods].key?(method_name)
        end

        # ── Instance Wrapping ───────────────────────────────────

        # Create a new AS instance wrapping a Ruby object.
        # Used when a native method returns an object that maps
        # to a known native class (e.g. Time → Czas).
        def wrap_native_object(as_class_name, ruby_obj)
          class_def = @class_defs[as_class_name]
          return nil unless class_def

          instance = {
            class_name: as_class_name,
            instance_vars: {},
            class_def: class_def,
            __native__: ruby_obj
          }
          [:type_instance, instance]
        end

        # Format a native instance for display (pokazl)
        def format_native_instance(instance)
          native_obj = instance[:__native__]
          return instance.to_s unless native_obj

          class_info = @classes[instance[:class_name]]
          if class_info && class_info[:methods].key?('do_tekstu')
            class_info[:methods]['do_tekstu'].call(native_obj)
          else
            native_obj.to_s
          end
        end

        # ── Cleanup ─────────────────────────────────────────────

        # Reset all registrations (useful for testing)
        def reset!
          @classes.clear
          @ruby_class_map.clear
          @class_defs.clear
          @libraries.clear
        end

        private

        # Convert a Ruby return value to AS [type, value].
        # Checks if the value is a known native class first.
        def convert_return(ruby_value)
          # Fast nil check
          return [:type_null, NULL_VALUE] if ruby_value.nil?

          # Check if return is a known native class → auto-wrap
          as_name = @ruby_class_map[ruby_value.class]
          if as_name
            return wrap_native_object(as_name, ruby_value)
          end

          NativeTypeConverter.from_ruby(ruby_value)
        end

        # Build an interpreter-compatible class_def hash from class_info.
        # Called once at registration time, result is cached.
        def build_class_def(class_info)
          # Convert static_vars from Ruby values to AS format
          converted_static_vars = {}
          class_info[:static_vars].each do |name, ruby_value|
            r = NativeTypeConverter.from_ruby(ruby_value)
            converted_static_vars[name] = { type: r[0], value: r[1] }
          end

          {
            parent: class_info[:parent],
            body: nil,
            methods: {},               # No AST-based methods
            static_methods: {},         # No AST-based static methods
            static_vars: converted_static_vars,
            is_abstract: false,
            included_modules: [],
            class_env: nil,

            # Native-specific fields
            native: true,
            native_constructor: class_info[:constructor],
            native_methods: class_info[:methods],
            native_static_methods: class_info[:static_methods],
            native_ruby_class: class_info[:ruby_class]
          }
        end
      end
    end
  end
end
