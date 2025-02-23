# frozen_string_literal: true

module AlexScript
  module Utils
    module Methods
      class IntegerMethods < BaseTypeHandler
        private

        def register_methods
          register_method('typ', ->(num) { 'calkowita' })
          register_method('napis', ->(num) { num.to_s })
          register_method('abs', ->(num) { num.abs })
          register_method('parzysta', lambda { |num|
            [:type_bool, num.even? ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE]
          })
          register_method('nieparzysta', lambda { |num|
            [:type_bool, num.odd? ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE]
          })
        end
      end
    end
  end
end
