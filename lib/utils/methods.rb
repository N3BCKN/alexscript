# frozen_string_literal: true

require 'byebug'

module BuiltInMethods
  class MethodRegistry
    def initialize
      @methods = {
        type_array: ArrayMethods.new,
        type_string: StringMethods.new,
        type_int: IntegerMethods.new,
        type_float: FloatMethods.new
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
      else raise "Unknown type for value: #{value}"
      end
    end
  end

  class ArrayMethods < BaseTypeHandler
    def register_methods
      register_method('dlg', ->(arr) { arr.size })
      register_method('typ', ->(num) { 'tablica' })
      register_method('dodaj', lambda { |arr, *elements|
        i = 0
        while i < elements.size
          arr << { type: get_element_type(elements[i]), value: elements[i] }
          i += 1
        end
        arr
      })
    end
  end

  class StringMethods < BaseTypeHandler
    private

    def register_methods
      register_method('dlg', ->(str) { str.length })
    end
  end

  class IntegerMethods < BaseTypeHandler
    private

    def register_methods
      register_method('typ', ->(num) { 'liczba całkowita' })
    end
  end

  class FloatMethods < BaseTypeHandler
    private

    def register_methods
      register_method('typ', ->(num) { 'liczba zmiennoprzecinkowa' })
    end
  end
end
