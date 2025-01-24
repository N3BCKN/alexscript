# frozen_string_literal: true

module Utils
  module Methods
    class MethodRegistry
      def initialize
        @methods = {
          type_array: ArrayMethods.new,
          type_string: StringMethods.new,
          type_int: IntegerMethods.new,
          type_float: FloatMethods.new,
          type_object: ObjectMethods.new
        }
      end

      def get_method(type, method_name)
        type_handler = @methods[type]
        return nil unless type_handler

        type_handler.get_method(method_name)
      end

      def register_type(type, handler)
        @methods[type] = handler
      end
    end

    class BaseTypeHandler
      def initialize
        @methods = {}
        register_methods

        register_method('metody', lambda { |obj|
          @methods.keys
        })
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
