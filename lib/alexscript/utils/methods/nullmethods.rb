# frozen_string_literal: true

module AlexScript
  module Utils
    module Methods
      class NullMethods < BaseTypeHandler
        private

        def register_methods
          register_method('typ', ->(_value) { 'nic' })
          register_method('napis', ->(_value) { 'nic' })
        end
      end
    end
  end
end