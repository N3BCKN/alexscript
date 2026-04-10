# frozen_string_literal: true

# lib/alexscript/utils/native_class_registry.rb
#
# Central registry for native (Ruby-backed) AlexScript classes.
# Native classes bypass AST interpretation — their methods are Ruby lambdas
# called directly by the interpreter.
#
# Key design: native methods are injected into the standard [:methods] and
# [:static_methods] hashes with a :native_lambda flag. This makes native
# classes fully compatible with inheritance, introspection, and super calls
# without any changes to environment.rb or introspection code.
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
    module NativeTypeConverter
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
      @classes = {}
      @ruby_class_map = {}
      @class_defs = {}
      @libraries = {}

      class << self

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
          @class_defs[name] = build_class_def(class_info)

          class_info
        end

        def registered?(name)
          @classes.key?(name)
        end

        def get(name)
          @classes[name]
        end

        def get_class_def(name)
          @class_defs[name]
        end

        # ── Library Registration ────────────────────────────────

        def register_library(name, &block)
          @libraries[name] = block
        end

        def native_library?(name)
          @libraries.key?(name)
        end

        def load_library(name, env)
          loader = @libraries[name]
          return false unless loader
          loader.call(env)
          true
        end

        def register_into_env(name, env)
          class_def = @class_defs[name]
          return false unless class_def
          env.define_class(name, class_def)
          true
        end

        # ── Dispatch ────────────────────────────────────────────

        def dispatch_constructor(class_name, as_args)
          class_info = @classes[class_name]
          return nil unless class_info

          if as_args.empty?
            class_info[:constructor].call
          else
            ruby_args = as_args.map { |a| NativeTypeConverter.to_ruby(a[0], a[1]) }
            class_info[:constructor].call(*ruby_args)
          end
        end

        def dispatch_native_lambda(native_lambda, native_obj, as_args)
          if as_args.empty?
            result = native_lambda.call(native_obj)
          else
            ruby_args = as_args.map { |a| NativeTypeConverter.to_ruby(a[0], a[1]) }
            result = native_lambda.call(native_obj, *ruby_args)
          end
          convert_return(result)
        end

        def dispatch_static_lambda(native_lambda, as_args)
          if as_args.empty?
            result = native_lambda.call
          else
            ruby_args = as_args.map { |a| NativeTypeConverter.to_ruby(a[0], a[1]) }
            result = native_lambda.call(*ruby_args)
          end
          convert_return(result)
        end

        # Keep old dispatch methods for backward compat
        def dispatch_instance_method(instance, method_name, as_args)
          native_obj = instance[:__native__]
          class_info = @classes[instance[:class_name]]
          lambda_fn = class_info[:methods][method_name]
          dispatch_native_lambda(lambda_fn, native_obj, as_args)
        end

        def dispatch_static_method(class_name, method_name, as_args)
          class_info = @classes[class_name]
          lambda_fn = class_info[:static_methods][method_name]
          dispatch_static_lambda(lambda_fn, as_args)
        end

        # ── Instance Wrapping ───────────────────────────────────

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

        def reset!
          @classes.clear
          @ruby_class_map.clear
          @class_defs.clear
          @libraries.clear
        end

        def convert_return(ruby_value)
          return [:type_null, NULL_VALUE] if ruby_value.nil?

          as_name = @ruby_class_map[ruby_value.class]
          if as_name
            return wrap_native_object(as_name, ruby_value)
          end

          NativeTypeConverter.from_ruby(ruby_value)
        end

        private

        # Build interpreter-compatible class_def.
        # Native methods are injected into [:methods] / [:static_methods]
        # with :native_lambda flag — visible to inheritance + introspection.
        def build_class_def(class_info)
          converted_static_vars = {}
          class_info[:static_vars].each do |name, ruby_value|
            r = NativeTypeConverter.from_ruby(ruby_value)
            converted_static_vars[name] = { type: r[0], value: r[1] }
          end

          # Inject native instance methods into [:methods]
          methods = {}
          class_info[:methods].each do |name, lambda_fn|
            methods[name] = {
              declaration: nil,
              env: nil,
              private: false,
              native_lambda: lambda_fn
            }
          end

          # Inject native static methods into [:static_methods]
          static_methods = {}
          class_info[:static_methods].each do |name, lambda_fn|
            static_methods[name] = {
              declaration: nil,
              env: nil,
              private: false,
              native_lambda: lambda_fn
            }
          end

          {
            parent: class_info[:parent],
            body: nil,
            methods: methods,
            static_methods: static_methods,
            static_vars: converted_static_vars,
            is_abstract: false,
            included_modules: [],
            class_env: nil,

            native: true,
            native_constructor: class_info[:constructor],
            native_ruby_class: class_info[:ruby_class]
          }
        end
      end
    end
  end
end