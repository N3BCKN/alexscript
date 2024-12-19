# frozen_string_literal: true

require 'byebug'

class Interpreter
  def init
  end

  def interpret!(node, env)
    if node.is_a? Int
      [:type_number, node.value.to_f]
    elsif node.is_a? Flt
      [:type_number, node.value.to_f]
    elsif node.is_a? Str
      [:type_string, node.value.to_s]
    elsif node.is_a? Bool
      [:type_bool, node.value]
    elsif node.is_a? Grouping
      interpret!(node.value, env)
    elsif node.is_a? Identifier
      value = env.get_var(node.name)
      Utils.runtime_error("Undeclared identifier #{node.name}", node.line) if value.nil?
      Utils.runtime_error("Uninitialized identifier #{node.name}", node.line) if value[1].nil?
      value
    elsif node.is_a? Assignment
      # evaluate right side of the expression
      right_type, right_value = interpret!(node.right, env)
      # assign new value or overwrite existing one
      env.set_var(node.left.name, [right_type, right_value])
    elsif node.is_a? LocalAssignment
      # evaluate right side of the expression
      right_type, right_value = interpret!(node.right, env)
      # assign new value or overwrite existing one
      env.set_local(node.left.name, [right_type, right_value])
    elsif node.is_a? BinOp
      left_type,  left_value  = interpret!(node.left, env)
      right_type, right_value = interpret!(node.right, env)

      if node.op.token_type == :tok_plus # addition +
        if left_type == :type_number && right_type == :type_number #
          [:type_number, left_value + right_value]
        elsif left_type == :type_string || right_type == :type_string # addition of strings or strings and numbers
          [:type_string, left_value.to_s + right_value.to_s]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_minus # substraction -
        if left_type == :type_number && right_type == :type_number
          [:type_number, left_value - right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_star # multiplication *
        if left_type == :type_number && right_type == :type_number
          [:type_number, left_value * right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_slash # divisions /
        Utils.runtime_error('Division by zero', node.op.line) if right_value == 0

        if left_type == :type_number && right_type == :type_number
          [:type_number, left_value / right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_mod # modulo %
        if left_type == :type_number && right_type == :type_number
          [:type_number, left_value % right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_caret # exponentiation ^
        if left_type == :type_number && right_type == :type_number
          [:type_number, left_value**right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_greater # >
        if (left_type == :type_number && right_type == :type_number) || (left_type == :type_string && right_type == :type_string)
          [:type_bool, left_value > right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_greateroreq # >=
        if (left_type == :type_number && right_type == :type_number) || (left_type == :type_string && right_type == :type_string)
          [:type_bool, left_value >= right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_smaller # <
        if (left_type == :type_number && right_type == :type_number) || (left_type == :type_string && right_type == :type_string)
          [:type_bool, left_value < right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_smalleroreq # <=
        if (left_type == :type_number && right_type == :type_number) || (left_type == :type_string && right_type == :type_string)
          [:type_bool, left_value <= right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_eq # ==
        if (left_type == :type_number && right_type == :type_number) || (left_type == :type_string && right_type == :type_string)
          [:type_bool, left_value == right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_noteq # !=
        if (left_type == :type_number && right_type == :type_number) || (left_type == :type_string && right_type == :type_string)
          [:type_bool, left_value != right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      end

    elsif node.is_a? UnOp
      operand_type, operand_value = interpret!(node.operand, env)

      if node.op.token_type == :tok_plus
        if operand_type == :type_number
          [:type_number, +operand_value]
        else
          runtime_error_unop(operand_value, node)
        end
      elsif node.op.token_type == :tok_minus
        if operand_type == :type_number
          [:type_number, -operand_value]
        else
          runtime_error_unop(operand_value, node)
        end
      elsif node.op.token_type == :tok_not
        if operand_type == :type_bool
          [:type_bool, !operand_value]
        else
          runtime_error_unop(operand_value, node)
        end
      end

    # short-circut evaluation for logical operators, left 'and' is false => false, left 'or' is true => true
    # otherwise search for the right side
    elsif node.is_a? LogicalOp
      left_type, left_value = interpret!(node.left, env)
      if node.op.token_type == :tok_or
        return [left_type, left_value] if left_value
      elsif node.op.token_type == :tok_and
        return [left_type, left_value] unless left_value
      end
      interpret!(node.right, env)
    elsif node.is_a? Stmts
      i = 0
      while i < node.stmts.size
        interpret!(node.stmts[i], env)
        i += 1
      end
    elsif node.is_a? PrintStmt
      expression_type, expression_value = interpret!(node.value, env)
      print(expression_value)

    elsif node.is_a? PrintlnStmt
      expression_type, expression_value = interpret!(node.value, env)
      puts(expression_value)

    elsif node.is_a? IfStmt
      test_type, test_value = interpret!(node.test, env)
      # TODO: export it to a general private method
      # TODO: use the same type of testing conditions just like in JS (nil, false and 0 would not pass only)
      Utils.runtime_error("Condition type #{test_value} is not a boolean", node.op.line) unless test_type == :type_bool

      if test_value
        interpret!(node.then_stmt, env.new_env) # new child, nested env for if-else block
      else
        interpret!(node.else_stmt, env.new_env)
      end
    elsif node.is_a? WhileStmt
      # Create a new environment for the while loop scope
      loop_env = env.new_env

      loop do
        # Evaluate test condition in the parent environment
        test_type, test_value = interpret!(node.test, env)

        # Validate the test condition type
        Utils.runtime_error('While test is not a boolean expression', node.line) if test_type != :type_bool

        # Exit loop if condition is false
        break unless test_value

        # Execute body in the loop's environment
        interpret!(node.body_statement, loop_env)
      end

    elsif node.is_a? ForStmt
      var_name = node.identifier.name
      index_type, index_value = interpret!(node.start_statement, env)
      end_type, end_value = interpret!(node.end_statement, env)

      # Create a new environment for the while loop scope
      loop_env = env.new_env
      if index_value < end_value
        if node.step_statement.nil?
          step = 1
        else
          step_type, step = interpret!(node.step_statement, env)
        end
        while index_value <= end_value
          new_value = [:type_number, index_value]
          env.set_var(var_name, new_value)
          interpret!(node.body_statement, loop_env)
          index_value += step
        end
      else
        if node.step_statement.nil?
          step = -1
        else
          step_type, step = interpret!(node.step_statement, env)
        end
        while index_value >= end_value
          new_value = [:type_number, index_value]
          env.set_var(var_name, new_value)
          interpret!(node.body_statement, loop_env)
          index_value += step
        end
      end
    elsif node.is_a? FuncDclr
      # store entire parsed 'body' of the function with its current env
      env.set_func(node.name, [node, env]) # TODO: improve memory management here
    elsif node.is_a? FuncCall
      func = env.get_func(node.name)
      # check if function was declared
      # todo: consider exporint this into a method
      Utils.runtime_error("Function #{node.name} was not declared in current scope", node.line) unless func

      # fetch function declaration
      func_declr = func[0] # entire func declaration
      func_env   = func[1] # function env

      # check if number of args matches expected number of params in func delcaration
      if func_declr.params.size != node.arguments.size
        Utils.runtime_error(
          "Function #{node.name} expected #{func_declr.params.size} arguments, got #{node.arguments.size} instead", node.line
        )
      end

      # evalate args
      arguments = []
      node.arguments.each { |arg| arguments << interpret!(arg, env) }

      # new nested env for function, derrived from the original env of the function where it was declared
      # (eg, could be nested func or smth)
      new_func_env = func_env.new_env

      # create local variables for called function, derrived from args
      # eg. my_func(1,2,3), my_func(a,b,c) => a = 1, b = 2, c = 3
      func_declr.params.zip(arguments).each do |param, argval|
        new_func_env.set_local(param.name, argval)
      end

      # interpret function declaration body, wrap in into a rescue block to catch a return statement
      begin
        interpret!(func_declr.body_statement, new_func_env)
      rescue ReturnError => e
        e.value
      end
    elsif node.is_a? FuncCallStmt
      interpret!(node.expression, env)
    elsif node.is_a? ReturnStatement
      raise ReturnError.new(interpret!(node.value, env))
    end
  end

  # entry point of interpreter creating brand new global/parent environment
  def interpret_ast(node)
    env = Environment.new
    interpret!(node, env)
  end

  private

  def runtime_error(left_value, right_value, node)
    Utils.runtime_error("Unsupported operator #{node.op.lexeme} between #{left_value} and #{right_value}", node.op.line)
  end

  def runtime_error_unop(value, node)
    Utils.runtime_error("Unsupported operator #{node.op.lexeme} with #{value}", node.op.line)
  end
end

# TODO: export this to another file
class ReturnError < StandardError
  attr_reader :value

  def initialize(value)
    @value = value
    super()
  end
end
