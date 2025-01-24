# frozen_string_literal: true

module Utils
  module Methods
    class FloatMethods < BaseTypeHandler
      private

      def register_methods
        register_method('typ', ->(num) { 'liczba zmiennoprzecinkowa' })
      end
    end
  end
end
