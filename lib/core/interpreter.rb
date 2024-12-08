# frozen_string_literal: true
require 'byebug'


class Interpreter 
  def init
  end

  def interpret!(node)   
    if node.is_a? Int
      return [:type_number, node.value.to_f]
    elsif node.is_a? Flt
      return [:type_number, node.value.to_f]
    elsif node.is_a? Str
      return [:type_string, node.value.to_s]
    elsif node.is_a? Bool
      return [:type_bool, node.value]
    elsif node.is_a? Grouping
      return interpret!(node.value)
    elsif node.is_a? BinOp
      left_type,  left_value  = interpret!(node.left)
      right_type, right_value = interpret!(node.right)
      
      if node.op.token_type == :tok_plus #addition +
        if left_type == :type_number && right_type == :type_number #
          return [:type_number, left_value + right_value]
        elsif left_type == :type_string || right_type == :type_string # addition of strings or strings and numbers 
          return [:type_string, left_value.to_s + right_value.to_s]
        else
          runtime_error(left_value, right_value, node)
        end 
      elsif node.op.token_type == :tok_minus #substraction -
        if left_type == :type_number && right_type == :type_number 
          return [:type_number, left_value - right_value]
        else
          runtime_error(left_value, right_value, node)
        end 
      elsif node.op.token_type == :tok_star #multiplication * 
        if left_type == :type_number && right_type == :type_number 
          return [:type_number, left_value * right_value]
        else
          runtime_error(left_value, right_value, node)
        end 
      elsif node.op.token_type == :tok_slash #divisions /
        Utils.runtime_error("Division by zero", node.op.line) if right_value == 0
        
        if left_type == :type_number && right_type == :type_number 
          return [:type_number, left_value / right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_mod #modulo %
        if left_type == :type_number && right_type == :type_number 
          return [:type_number, left_value % right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_caret #exponentiation ^
        if left_type == :type_number && right_type == :type_number 
          return [:type_number, left_value ** right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_greater # >
        if (left_type == :type_number && right_type == :type_number) || (left_type == :type_string && right_type == :type_string)
          return [:type_bool, left_value > right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_greateroreq # >=
        if (left_type == :type_number && right_type == :type_number) || (left_type == :type_string && right_type == :type_string)
          return [:type_bool, left_value >= right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_greater # <
        if (left_type == :type_number && right_type == :type_number) || (left_type == :type_string && right_type == :type_string)
          return [:type_bool, left_value < right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_greater # <=
        if (left_type == :type_number && right_type == :type_number) || (left_type == :type_string && right_type == :type_string)
          return [:type_bool, left_value <= right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_eq # ==
        if (left_type == :type_number && right_type == :type_number) || (left_type == :type_string && right_type == :type_string)
          return [:type_bool, left_value == right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_noteq # !=
        if (left_type == :type_number && right_type == :type_number) || (left_type == :type_string && right_type == :type_string)
          return [:type_bool, left_value != right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      end
  
    elsif node.is_a? UnOp
      operand_type, operand_value = interpret!(node.operand)
      
      if node.op.token_type == :tok_plus
        if operand_type == :type_number
          return [:type_number, +operand_value]
        else
          runtime_error_unop(operand_value, node)
        end 
      elsif node.op.token_type == :tok_minus
        if operand_type == :type_number
          return [:type_number, -operand_value]
        else
          runtime_error_unop(operand_value, node)
        end 
      elsif node.op.token_type == :tok_not
        if operand_type == :type_bool
          return [:type_bool, !operand_value]
        else
          runtime_error_unop(operand_value, node)
        end 
      end
    
    # short-circut evaluation for logical operators, left 'and' is false => false, left 'or' is true => true 
    # otherwise search for the right side 
    elsif node.is_a? LogicalOp
      left_type, left_value = interpret!(node.left)
      if node.op.token_type == :tok_or
        return [left_type, left_value] if left_value
      elsif node.op.token_type == :tok_and
        return [left_type, left_value] unless left_value
      end
      return interpret!(node.right)
    end 
  end


  private
  def runtime_error(left_value, right_value, node)
    Utils.runtime_error("Unsupported operator #{node.op.lexeme} between #{left_value} and #{right_value}", node.op.line)
  end

  def runtime_error_unop(value, node)
    Utils.runtime_error("Unsupported operator #{node.op.lexeme} with #{value}", node.op.line)
  end

  
end