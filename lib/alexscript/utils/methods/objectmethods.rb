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
              k_type, k_value = Utils.object_key_typed(k)
              { type: :type_array, value: [{ type: k_type, value: k_value }, v_typed] }
            end
            [:type_array, pairs]
          })

          register_method('klucze', lambda { |obj|
            keys = obj.keys.map do |k|
              k_type, k_value = Utils.object_key_typed(k)
              { type: k_type, value: k_value }
            end
            [:type_array, keys]
          })

          register_method('pusty', lambda { |obj|
            [:type_bool, obj.empty? ? Utils::BOOL_TRUE : Utils::BOOL_FALSE]
          })

          register_method('ma_klucz', lambda { |obj, key|
            rk = Utils.object_key_for_lookup(key)
            [:type_bool, obj.has_key?(rk) ? Utils::BOOL_TRUE : Utils::BOOL_FALSE]
          })

          register_method('ma_wartosc', lambda { |obj, val|
            vals = obj.map { |key, array| array[:value] }

            [:type_bool, vals.include?(val) ? Utils::BOOL_TRUE : Utils::BOOL_FALSE]
          })

          register_method('usun', lambda { |obj, key|
            obj.delete(Utils.object_key_for_lookup(key))
          })
        end
      end
    end
  end
end