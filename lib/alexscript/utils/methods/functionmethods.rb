# functionmethods.rb
module AlexScript
  module Utils
    module Methods
      class FunctionMethods < BaseTypeHandler
        private

        def register_methods
          register_method('typ', ->(_f) { 'funkcja' })

          register_method('napis', lambda { |f|
            "#<funkcja:0x#{f.object_id.to_s(16)}>"
          })
        end
      end
    end
  end
end