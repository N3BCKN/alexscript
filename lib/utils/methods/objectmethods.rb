# frozen_string_literal: true

module AlexScript
  module Utils
    module Methods
      class ObjectMethods < BaseTypeHandler
        def register_methods
          register_method('typ', ->(obj) { 'obiekt' })
          register_method('dlg', ->(obj) { obj.size })
          register_method('klucze', ->(obj) { obj.keys })
          register_method('wartosci', ->(obj) { obj.values })
          register_method('wyczysc', ->(obj) { obj.clear })
          register_method('na_tablice', ->(obj) { obj.to_a })

          register_method('pusty', lambda { |obj|
            [:type_bool, obj.empty? ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE]
          })

          register_method('ma_klucz', lambda { |obj, key|
            [:type_bool, obj.has_key?(key) ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE]
          })
          register_method('ma_wartosc', lambda { |obj, val|
            vals = obj.map { |key, array| array[:value] }

            [:type_bool, vals.include?(val) ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE]
          })

          register_method('usun', lambda { |obj, key|
            obj.delete(key)
          })
        end
      end
    end
  end
end
