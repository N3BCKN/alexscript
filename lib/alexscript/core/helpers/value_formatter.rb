# frozen_string_literal: true

# Formats AS values for display (print/println).
# Handles nested arrays and objects, recursively formatting complex structures
# into human-readable strings.


module AlexScript
  module Core
    module Helpers
      module ValueFormatter

        def format_value(type, value)
          case type
          when :type_bool, :type_null
            # PrimivieValue objects display without quotes
            value.to_s
          when :type_string
            # Strings are displayed with quotes
            value.to_s
          when :type_array
            format_array_value(value)
          when :type_object
            format_object_value(value)
          else
            value
          end
        end

        def format_array_value(value)
          if value.is_a?(Array)
            value.map do |elem|
              if elem.is_a?(Hash)
                if elem[:type] == :type_array
                  format_array_value(elem[:value])
                elsif elem[:type] == :type_object
                  format_object_value(elem[:value])
                else
                  elem[:value]
                end
              else
                elem
              end
            end
          else
            value
          end
        end

        def format_object_value(object)
          pairs = object.map do |key, value|
            formatted_value = if value.is_a?(Hash)
                                [value[:type], value[:value]]
                              else
                                [:type_string, value]
                              end

            formatted = format_value(formatted_value[0], formatted_value[1])
            "#{key}: #{formatted}"
          end
          "{#{pairs.join(', ')}}"
        end
      end
    end
  end 
end 