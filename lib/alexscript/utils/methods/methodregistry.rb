# frozen_string_literal: true

require 'singleton'

module AlexScript
  module Utils
    module Methods
      class MethodRegistry
        include Singleton
        
        def initialize
          @methods = {
            type_array: ArrayMethods.instance,
            type_string: StringMethods.instance,
            type_int: IntegerMethods.instance,
            type_float: FloatMethods.instance,
            type_object: ObjectMethods.instance,
            type_class: ClassMethods.instance,
            type_instance: InstanceMethods.instance,
            type_bool: BoolMethods.instance,
            type_null: NullMethods.instance,
            type_module: ModuleMethods.instance,
            type_function: FunctionMethods.instance
          }.freeze
        end

        def get_method(type, method_name)
          type_handler = @methods[type]
          return nil unless type_handler

          type_handler.get_method(method_name)
        end

        def register_type(type, handler)
          # This method is no longer needed since we use singletons
          # but keeping for backward compatibility
          raise "Cannot register types on singleton MethodRegistry. Use singleton handlers instead."
        end
      end

      class BaseTypeHandler
        include Singleton
        
        def initialize
          @methods = {}
          # Names registered via register_typed_method. Must exist before
          # register_methods runs.
          @typed_methods = Set.new
          register_methods

          unless @methods.key?('metody')
            register_method('metody', lambda { |obj|
              alex_string_array(@methods.keys.sort)
            })
          end

          @methods.freeze
          @typed_methods.freeze
        end

        def get_method(name)
          @methods[name]
        end

        # True when this method wants { type:, value: } pairs instead of bare
        # Ruby values. Frozen Set — O(1), no allocation.
        def typed_method?(name)
          @typed_methods.include?(name)
        end

        def alex_string_array(ruby_array)
          as_array = ruby_array.map { |str| {type: :type_string, value: str} }
          [:type_array, as_array]
        end

        def alex_object(ruby_hash)
          alex_hash = {}
          ruby_hash.each do |key, value|
            value_type = case value
                        when Integer then :type_int
                        when String then :type_string
                        when Utils::PrimitiveValue then (value.bool? ? :type_bool : :type_null)
                        when TrueClass, FalseClass then :type_bool
                        when NilClass then :type_null
                        else :type_object
                        end
            alex_hash[key] = {type: value_type, value: value}
          end
          [:type_object, alex_hash]
        end

        private

        def register_method(name, method)
          @methods[name] = method
        end


        # Registers a method whose behaviour depends on the AlexScript type of
        # its arguments, not just on their Ruby representation. The interpreter
        # hands such methods { type:, value: } hashes, so they never re-derive a
        # type that was already known. Use this for anything that stores an
        # argument into a container.
        def register_typed_method(name, method)
          @typed_methods << name
          @methods[name] = method
        end

        def get_element_type(value)
          case value
          when Integer then :type_int
          when Float   then :type_float
          when String  then :type_string
          when Utils::PrimitiveValue
            # prawda / falsz / nic — frozen singletons, NOT Ruby true/false/nil
            value.bool? ? :type_bool : :type_null
          when TrueClass, FalseClass then :type_bool
          when NilClass then :type_null
          when Array then :type_array
          when Hash
            if value.key?(:class_name) && value.key?(:instance_vars)
              :type_instance
            elsif value.key?(:declaration) && value.key?(:env)
              :type_function
            elsif value.key?(:methods) && value.key?(:static_methods)
              :type_class
            elsif value.key?(:functions) && value.key?(:nested_modules)
              :type_module
            else
              :type_object
            end
          else raise "Unknown type for value: #{value}"
          end
        end
      end
    end
  end
end