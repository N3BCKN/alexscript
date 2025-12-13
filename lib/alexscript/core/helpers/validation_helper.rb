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

        def runtime_error(left_value, right_value, node)
          Utils.runtime_error("Niewspierany operator #{node.op.lexeme} pomiedzy #{left_value} a #{right_value}",
                              node.op.line)
        end

        def runtime_error_unop(value, node)
          Utils.runtime_error("Niewspierany operator #{node.op.lexeme} z #{value}", node.op.line)
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