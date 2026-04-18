# frozen_string_literal: true

# validates function calls and raises runtime errors.
# checks function value types, validates operations, and provides error reporting
# with line number tracking.


module AlexScript
  module Core
    module Helpers
      module ValidationHelper
        def validate_function_value(val)
          return false unless val && val[:type] == :type_function
          return false unless val[:value] && val[:value][:declaration] && val[:value][:env]
          true
        end

        def runtime_error(left_type, left_value, right_type, right_value, node)
          Utils.runtime_error(
            "Niewspierany operator #{node.op.lexeme} pomiedzy " \
            "#{format_operand_for_error(left_type, left_value)} a " \
            "#{format_operand_for_error(right_type, right_value)}",
            node.op.line
          )
        end

        def runtime_error_unop(type, value, node)
          Utils.runtime_error(
            "Niewspierany operator #{node.op.lexeme} z #{format_operand_for_error(type, value)}",
            node.op.line
          )
        end

        # short, user-facing representation of an operand for error messages
        # never dumps internal environment / class_def / module_def hashes, which would otherwise leak via Hash#to_s string interpolation
        def format_operand_for_error(type, value)
          case type
          when :type_module
            "modul #{value.is_a?(Hash) ? (value[:name] || '?') : value}"
          when :type_class
            "klasa #{value.is_a?(Hash) ? (value[:name] || '?') : value}"
          when :type_function
            "<funkcja>"
          when :type_instance
            "<instancja #{value.is_a?(Hash) ? (value[:class_name] || '?') : '?'}>"
          when :type_string
            "\"#{value}\""
          when :type_bool
            value == Utils::BOOL_TRUE ? 'prawda' : 'falsz'
          when :type_null
            'nic'
          when :type_array
            "[tablica(#{value.is_a?(Array) ? value.size : '?'})]"
          when :type_object
            "{obiekt(#{value.is_a?(Hash) ? value.size : '?'})}"
          else
            value.to_s
          end
        end

        def get_access_path(node, env)
					if node.is_a?(AST::Identifier)
						node.name
					elsif node.is_a?(AST::ObjectOrArrayAccess)
						base = get_access_path(node.array, env)
						key_type, key_value = interpret!(node.index, env)
						"#{base}[#{key_value}]"
					elsif node.is_a?(AST::ObjectOrArrayAssignment)
						base = get_access_path(node.array, env)
						key_type, key_value = interpret!(node.index, env)
						"#{base}[#{key_value}]"
					end
        end
      end
    end
  end 
end