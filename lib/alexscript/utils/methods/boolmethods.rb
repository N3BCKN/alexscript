# frozen_string_literal: true

module AlexScript
  module Utils
    module Methods
      class BoolMethods < BaseTypeHandler
        private

        def register_methods
          register_method('typ', ->(value) { 'logiczna' })
          register_method('napis', ->(value) { value.to_s })
        end
      end
    end
  end
end