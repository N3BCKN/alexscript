# frozen_string_literal: true

module Utils
  module Methods
    class ObjectMethods < BaseTypeHandler
      def register_methods
        register_method('typ', ->(obj) { 'obiekt' })
        register_method('klucze', ->(obj) { obj.keys })
        register_method('wartosci', ->(obj) { obj.values })
      end
    end
  end
end
