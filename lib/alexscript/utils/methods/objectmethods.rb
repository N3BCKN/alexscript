# frozen_string_literal: true

module AlexScript
  module Utils
    module Methods
      class ObjectMethods < BaseTypeHandler
        def register_methods
          register_method('typ', ->(obj) { 'obiekt' })
          register_method('dlg', ->(obj) { obj.size })
          register_method('wartosci', ->(obj) { obj.values })
          register_method('wyczysc', ->(obj) { obj.clear })
          
          register_method('na_tablice', lambda { |obj|
            pairs = obj.map do |k, v_typed|
              inner = [
                { type: :type_string, value: k.to_s },
                v_typed
              ]
              { type: :type_array, value: inner }
            end
            [:type_array, pairs]
          })

          register_method('klucze', lambda { |obj|
            alex_string_array(obj.keys)
          })

          register_method('pusty', lambda { |obj|
            [:type_bool, obj.empty? ? Utils::BOOL_TRUE : Utils::BOOL_FALSE]
          })

          register_method('ma_klucz', lambda { |obj, key|
            [:type_bool, obj.has_key?(key) ? Utils::BOOL_TRUE : Utils::BOOL_FALSE]
          })
          register_method('ma_wartosc', lambda { |obj, val|
            vals = obj.map { |key, array| array[:value] }

            [:type_bool, vals.include?(val) ? Utils::BOOL_TRUE : Utils::BOOL_FALSE]
          })

          register_method('usun', lambda { |obj, key|
            obj.delete(key)
          })
        end
      end
    end
  end
end