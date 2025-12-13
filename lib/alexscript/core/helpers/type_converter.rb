# frozen_string_literal: true

# converts between AS and Ruby boolean representations.
# manages truthiness checking and bool value conversions (prawda/falsz <-> true/false).

module AlexScript
  module Core
    module Helpers
      module TypeConverter

        def to_bool_value(ruby_bool)
          ruby_bool ? Utils::BOOL_TRUE : Utils::BOOL_FALSE
        end

        def from_bool_value(alex_bool)
          alex_bool == Utils::BOOL_TRUE
        end

        def is_truthy?(type, value, line)
          case type
          when :type_bool
            value == Utils::BOOL_TRUE
          when :type_null
            false
          else
            Utils.runtime_error('Warunek musi byc boolem lub "nic"', line)
          end
        end
      end
    end
  end 
end 