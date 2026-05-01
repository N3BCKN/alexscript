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
            value.to_s
          when :type_string
            value.to_s
          when :type_array
            format_array_value(value)
          when :type_object
            format_object_value(value)
          when :type_module
            "modul #{value.is_a?(Hash) ? (value[:name] || 'UnnamedModule') : value}"
          when :type_instance
            format_instance_value(value)
          when :type_function
            "<funkcja>"
          when :type_class
            format_class_value(value)
          else
            value
          end
        end

        def format_instance_value(instance)
          return instance.to_s unless instance.is_a?(Hash)
          class_name = instance[:class_name] || 'UnknownClass'
          hex_id = instance.object_id.to_s(16)
          "#<#{class_name}:0x#{hex_id}>"
        end

        def format_class_value(klass)
          return "<klasa>" unless klass.is_a?(Hash)
          name = klass[:name] || 'UnnamedClass'
          parent = klass[:parent]
          parent ? "klasa #{name} < #{parent}" : "klasa #{name}"
        end

        def format_array_value(value)
          if value.is_a?(Array)
            value.map do |elem|
              if elem.is_a?(Hash) && elem.key?(:type)
                # Element is a typed AS value tuple — dispatch to format_value
                # so :type_function, :type_class, :type_instance, etc. get
                # readable representations instead of raw Ruby dumps.
                format_value(elem[:type], elem[:value])
              else
                elem
              end
            end
          else
            value
          end
        end

        def format_function_value(_fn)
          "<funkcja>"
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

        def stringify_for_interpolation(type, value)
          case type
            when :type_string then value.to_s
            when :type_null then 'nic'
            when :type_bool then value == Utils::BOOL_TRUE ? 'prawda' : 'falsz'
            when :type_int, :type_float then value.to_s
            when :type_array then format_array_value(value).to_s
            when :type_object then format_object_value(value)
            when :type_function then '<funkcja>'
            when :type_instance then "<#{value[:class_name]} instancja>"
            when :type_class then "klasa #{value.is_a?(Hash) ? (value[:name] || 'UnnamedClass') : value}"
            else value.to_s
          end
        end
      end
    end
  end 
end