# frozen_string_literal: true

module AlexScript
  module Utils
    module Methods
      class ArrayMethods < BaseTypeHandler
        def register_methods
          register_method('dlg', ->(arr) { arr.size })

          register_method('typ', lambda { |num|
            'tablica'
          })

          # TODO: its' redundancy, interpreter pack this again in [type, value] format, find a way to get gid of it
          register_method('pierwszy', lambda { |arr|
              return [:type_null, Utils::NULL_VALUE] if arr.empty?

              element = arr.first
              [element[:type], element[:value]]
          })

          register_method('ostatni', lambda { |arr|
              return [:type_null, Utils::NULL_VALUE] if arr.empty?

              element = arr.last
              [element[:type], element[:value]]
          })

          register_method('indeks', lambda { |arr, element|
            unpacked = unpacked_arr(arr)
            unpacked.index(element).nil? ? [:type_null, Utils::NULL_VALUE] : unpacked.index(element)
          })

          # on elements
          register_method('usun', lambda { |arr, index|
            Utils.runtime_error('Indeks poza zakresem') if index < -arr.length || index >= arr.length
            arr.delete_at(index)
            arr
          })

          register_method('wstaw', lambda { |arr, index, element|
            Utils.runtime_error('Indeks poza zakresem') if index < -arr.length || index > arr.length
            arr.insert(index, { type: get_element_type(element), value: element })
            arr
          })

          register_method('dodaj', lambda { |arr, *elements|
            i = 0
            while i < elements.size
              arr << { type: get_element_type(elements[i]), value: elements[i] }
              i += 1
            end
            arr
          })

          # register_method('zamien', lambda { |arr, index1, index2|
          #   Utils.runtime_error('Indeks poza zakresem', nil) if index1 < -arr.length || index2 < -arr.length ||
          #                                                     index1 >= arr.length ||
          #                                                     index2 >= arr.length
          #   arr[index1], arr[index2] = arr[index2], arr[index1]
          #   arr
          # })

          # on entire array
          register_method('wyczysc', lambda { |arr|
            arr.clear
          })

          register_method('odwroc', lambda { |arr|
            arr[:value].reverse!
            arr[:value]
          })

          register_method('kopiuj', lambda { |arr|
            arr.map(&:clone)
          })

          register_method('polacz', lambda { |arr1, arr2|
            arr1 + arr2
          })

          register_method('pusta', lambda { |arr|
            [:type_bool, arr.empty? ? Utils::BOOL_TRUE : Utils::BOOL_FALSE]
          })

          register_method('odwroc', lambda { |arr|
            arr.reverse
          })

          register_method('zlacz', lambda { |arr, separator|
            unpacked_arr(arr).join(separator)
          })

          register_method('zawiera', lambda { |arr, element|
            # TODO: export this map to other method
            [:type_bool, if unpacked_arr(arr).include?(element)
                           Utils::BOOL_TRUE
                         else
                           Utils::BOOL_FALSE
                         end]
          })

          # on ranges
          register_method('wycinek', lambda { |arr, start, koniec|
            Utils.runtime_error('Indeks poza zakresem') if start < 0 || koniec >= arr.length
            arr[start..koniec]
          })

          # math operations, numeric arrays only
          register_method('suma', lambda { |arr|
            validate_numeric_array(arr)
            arr.sum { |e| e[:value] }
          })

          register_method('srednia', lambda { |arr|
            validate_numeric_array(arr) # Przekazujemy tablicę arr[:value]
            return 0 if arr.empty?

            arr.sum { |e| e[:value] } / arr.length.to_f
          })

          register_method('min', lambda { |arr|
            return [:type_null, Utils::NULL_VALUE] if arr.empty?

            validate_numeric_array(arr)
            arr.min_by { |e| e[:value] }[:value]
          })

          register_method('max', lambda { |arr|
            return [:type_null, Utils::NULL_VALUE] if arr.empty?

            validate_numeric_array(arr)
            arr.max_by { |e| e[:value] }[:value]
          })
        end

        private

        def validate_numeric_array(arr)
          return if arr.all? { |e| e[:type] == :type_int || e[:type] == :type_float }

          Utils.runtime_error('Tablica moze zawierac wylacznie liczby')
        end

        def create_typed_response(type, value)
          [type, value]
        end

        def unpacked_arr(arr)
          arr.map { |e| e[:value] }
        end
      end
    end
  end
end