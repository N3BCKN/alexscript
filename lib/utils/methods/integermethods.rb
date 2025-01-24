# frozen_string_literal: true

module Utils
  module Methods
    class IntegerMethods < BaseTypeHandler
      private

      def register_methods
        register_method('typ', ->(num) { 'liczba całkowita' })
      end
    end
  end
end
