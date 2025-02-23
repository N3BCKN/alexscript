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
          register_method('rozdziel', ->(str, separator) { str.split(separator) })

          register_method('liczba', lambda { |str|
            return [:type_null, 'nic'] unless float?(str)

            str.to_f
          })

          register_method('indeks', lambda { |str, i|
            return [:type_null, 'nic'] if str.empty?

            Utils.runtime_error('Index out of bounds') if i < -str.length || i >= str.length
            str[i]
          })

          register_method('zawiera', lambda { |str, element|
            [:type_bool, str.include?(element) ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE]
          })

          register_method('wydziel', lambda { |str, start, length|
            str.slice(start, length)
          })

          register_method('pusta', lambda { |str|
            [:type_bool, str.empty? ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE]
          })

          register_method('usun', lambda { |str, chars|
            str.delete!(chars)
          })
        end

        private

        def float?(str)
          !!Float(str)
        rescue StandardError
          false
        end
      end
    end
  end
end
