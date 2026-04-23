# frozen_string_literal: true

module AlexScript
  module Utils
    module Methods
      class StringMethods < BaseTypeHandler
        private

        def register_methods
          register_method('typ', lambda { |num|
            'napis'
          })
          register_method('dlg', ->(str) { str.length })
          register_method('zduzej', ->(str) { str.capitalize })
          register_method('duzymi', ->(str) { str.upcase })
          register_method('malymi', ->(str) { str.downcase })
          register_method('odwroc', ->(str) { str.reverse })
          register_method('wyczysc', ->(str) { str.strip })
          register_method('rozdziel', lambda { |str, separator = nil|
            parts = if separator.is_a?(Hash) && separator[:__native__].is_a?(Regexp)
                      str.split(separator[:__native__])
                    else
                      str.split(separator)
                    end
            alex_string_array(parts)
          })

          register_method('pasuje', lambda { |str, wzorzec|
            regexp = extract_regexp(wzorzec, 'pasuje')
            [:type_bool, regexp.match?(str) ? Utils::BOOL_TRUE : Utils::BOOL_FALSE]
          })

          register_method('dopasuj', lambda { |str, wzorzec|
            regexp = extract_regexp(wzorzec, 'dopasuj')
            match = regexp.match(str)
            next [:type_null, Utils::NULL_VALUE] if match.nil?
            Utils::NativeClassRegistry.wrap_native_object('Dopasowanie', match)
          })

          register_method('liczba', lambda { |str|
            return [:type_null, Utils::NULL_VALUE] unless float?(str)

            str.to_f
          })

          register_method('indeks', lambda { |str, i|
            return [:type_null, Utils::NULL_VALUE] if str.empty?

            Utils.runtime_error('Indeks poza zakresem') if i < -str.length || i >= str.length
            str[i]
          })

          register_method('zawiera', lambda { |str, element|
            [:type_bool, str.include?(element) ? Utils::BOOL_TRUE : Utils::BOOL_FALSE]
          })

          register_method('wydziel', lambda { |str, start, length|
            str.slice(start, length)
          })

          register_method('pusta', lambda { |str|
            [:type_bool, str.empty? ? Utils::BOOL_TRUE : Utils::BOOL_FALSE]
          })

          register_method('wycinek', lambda { |str, start, koniec|
              Utils.runtime_error('Indeks poza zakresem') if start < 0 || koniec >= str.length
              str[start..koniec]
          })

          register_method('usun', lambda { |str, chars|
            str.delete!(chars)
          })
        end

        private

        def extract_regexp(wzorzec, method_name)
          if wzorzec.is_a?(Hash) && (native = wzorzec[:__native__]).is_a?(Regexp)
            native
          else
            Utils.runtime_error(
              "Nieprawidlowy argument metody #{method_name}: oczekiwano obiektu Wyrazenie"
            )
          end
        end

        def float?(str)
          !!Float(str)
        rescue StandardError
          false
        end
      end
    end
  end
end