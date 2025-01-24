# frozen_string_literal: true

module Utils
  module Methods
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
  end
end
