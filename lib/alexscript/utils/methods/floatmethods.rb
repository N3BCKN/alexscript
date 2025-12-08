# frozen_string_literal: true

module AlexScript
  module Utils
    module Methods
      class FloatMethods < BaseTypeHandler
        private

        def register_methods
          register_method('typ', ->(num) { 'zmiennoprzecinkowa' })
          register_method('napis', ->(num) { num.to_s })
          register_method('abs', ->(num) { num.abs })
          register_method('zaokragl', ->(num, precision = 0) { num.round(precision) })
          register_method('zaokragl_dol', ->(num, precision = 0) { num.floor(precision) })
          register_method('zaokragl_gora', ->(num, precision = 0) { num.ceil(precision) })
        end
      end
    end
  end
end
