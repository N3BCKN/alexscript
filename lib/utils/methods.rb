# frozen_string_literal: true

require 'byebug'

module BuiltInMethods
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

  class ArrayMethods < BaseTypeHandler
    def register_methods
      register_method('dlg', ->(arr) { arr.size })
      register_method('typ', lambda { |num|
        'tablica'
      }) # TODO: find elegant way to get rid of useless argument in type methods
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

  class ObjectMethods < BaseTypeHandler
    def register_methods
      register_method('typ', ->(obj) { 'obiekt' })
      register_method('klucze', ->(obj) { obj.keys })
      register_method('wartosci', ->(obj) { obj.values })
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
