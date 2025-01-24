# frozen_string_literal: true

module Utils
  module Methods
    class StringMethods < BaseTypeHandler
      private

      def register_methods
        register_method('dlg', ->(str) { str.length })
      end
    end
  end
end
