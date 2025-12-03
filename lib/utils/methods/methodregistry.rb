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
            type_instance: InstanceMethods.instance
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
          register_methods
          
          register_method('metody', lambda { |obj|
            @methods.keys
          })
          
          # freeze methods hash to prevent modification
          @methods.freeze
        end

        def get_method(name)
          @methods[name]
        end

        private

        def register_method(name, method)
          @methods[name] = method
        end

        def get_element_type(value)
          case value
          when Integer then :type_int
          when Float then :type_float
          when String then :type_string
          when TrueClass, FalseClass then :type_bool
          when NilClass then :type_null
          when Array then :type_array
          when Hash then :type_object
          else raise "Unknown type for value: #{value}"
          end
        end
      end
    end
  end
end