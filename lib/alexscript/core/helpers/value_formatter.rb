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
          if is_exception_object?(object) 
              return format_exception_object(object) # TODO: this might help to format any huge dump env in the future
          end

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

        def format_exception_object(exception_obj)
          parts = []
          
          parts << "typ: #{exception_obj['typ'][:value]}" if exception_obj['typ']
          parts << "wiadomosc: #{exception_obj['wiadomosc'][:value]}" if exception_obj['wiadomosc']
          parts << "linia: #{exception_obj['linia'][:value]}" if exception_obj['linia']
          parts << "klasa: #{exception_obj['klasa'][:value]}" if exception_obj['klasa']
          
          if exception_obj['stos'] && exception_obj['stos'][:value].is_a?(Array)
            stack_lines = exception_obj['stos'][:value].map { |frame| frame[:value] }
            parts << "stos:\n" + stack_lines.join("\n")
          end
          
          "{#{parts.join(', ')}}"
        end

        def is_exception_object?(object)
          return false unless object.is_a?(Hash)
          
          # Exception objects have these specific fields
          object.key?('wiadomosc') && 
            object.key?('typ') && 
            object.key?('klasa') && 
            object.key?('instancja') &&
            object.key?('stos')
        end
      end
    end
  end 
end 