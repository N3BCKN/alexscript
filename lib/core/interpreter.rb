# frozen_string_literal: true

require 'byebug'

class Interpreter
  def init
  end

  def interpret!(node, env)
    if node.is_a? Int
      [:type_int, node.value.to_i]
    elsif node.is_a? Flt
      [:type_float, node.value.to_f]
    elsif node.is_a? Str
      [:type_string, node.value.to_s]
    elsif node.is_a? Bool
      [:type_bool, node.value]
    elsif node.is_a? Null
      [:type_null, 'nic']
    elsif node.is_a? Grouping
      interpret!(node.value, env)
    elsif node.is_a? Identifier
      var_raw = env.get_var(node.name)

      Utils.runtime_error("Undeclared identifier #{node.name}", node.line) if var_raw.nil? || var_raw[:value].nil?
      Utils.runtime_error("Uninitialized identifier #{node.name}", node.line) if var_raw[:type].nil?
      [var_raw[:type], var_raw[:value]]
    elsif node.is_a? Assignment
      var = env.get_var(node.left.name)
      if var.nil?
        Utils.runtime_error("Variable #{node.left.name} must be declared with 'niech' before assignment", node.line)
      elsif var[:constant]
        Utils.runtime_error("Variable #{node.left.name} is constant and cannot be mutated", node.line)
      end

      # evaluate right side of the expression
      right_type, right_value = interpret!(node.right, env)
      # assign new value or overwrite existing one
      env.set_var(node.left.name, right_value, right_type)
    elsif node.is_a? VariableDeclaration
      right_type, right_value = interpret!(node.right, env)
      # declare new variable
      var_name = node.left.name
      is_constant = var_name.match?(/^[A-Z_]+$/) # declare as constant if CAPITALIZED

      env.set_local_var(var_name, right_value, right_type, is_constant)
    elsif node.is_a? GlobalVariableDeclaration
      global_env = env.get_global_env

      right_type, right_value = interpret!(node.right, env)

      # declare new variable in global scope
      global_env.set_local_var(node.left.name, right_value, right_type)
    elsif node.is_a? BinOp

      left_type, left_value = interpret!(node.left, env)
      right_type, right_value = interpret!(node.right, env)

      # handle operations with null values
      if left_type == :type_null || right_type == :type_null
        case node.op.token_type
        when :tok_eq # ==
          return [:type_bool, left_type == right_type]
        when :tok_noteq # !=
          return [:type_bool, left_type != right_type]
        else
          return [:type_null, 'nic'] # all logical operations with null returns null
        end
      end

      if node.op.token_type == :tok_plus # addition +
        case [left_type, right_type]
        when %i[type_int type_int]
          [:type_int, left_value + right_value]
        when %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
          [:type_float, left_value.to_f + right_value.to_f]
        when %i[type_string type_string], %i[type_string type_int], %i[type_string type_float],
             %i[type_int type_string], %i[type_float type_string]
          [:type_string, left_value.to_s + right_value.to_s]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_minus # subtraction -
        case [left_type, right_type]
        when %i[type_int type_int]
          [:type_int, left_value - right_value]
        when %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
          [:type_float, left_value.to_f - right_value.to_f]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_star # multiplication *
        case [left_type, right_type]
        when %i[type_int type_int]
          [:type_int, left_value * right_value]
        when %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
          [:type_float, left_value.to_f * right_value.to_f]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_slash # division /
        Utils.runtime_error('Division by zero', node.op.line) if right_value == 0

        case [left_type, right_type]
        when %i[type_int type_int]
          # If both are integers but result has decimal part, convert to float
          result = left_value.to_f / right_value.to_f
          result == result.to_i ? [:type_int, result.to_i] : [:type_float, result]
        when %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
          [:type_float, left_value.to_f / right_value.to_f]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_mod # modulo %
        case [left_type, right_type]
        when %i[type_int type_int]
          [:type_int, left_value % right_value]
        when %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
          [:type_float, left_value.to_f % right_value.to_f]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_caret # exponentiation ^
        case [left_type, right_type]
        when %i[type_int type_int]
          result = left_value**right_value
          result == result.to_i ? [:type_int, result.to_i] : [:type_float, result.to_f]
        when %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
          [:type_float, left_value.to_f**right_value.to_f]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_greater # >
        case [left_type, right_type]
        when %i[type_int type_int], %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
          [:type_bool, left_value > right_value]
        when %i[type_string type_string]
          [:type_bool, left_value > right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_greateroreq # >=
        case [left_type, right_type]
        when %i[type_int type_int], %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
          [:type_bool, left_value >= right_value]
        when %i[type_string type_string]
          [:type_bool, left_value >= right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_smaller # <
        case [left_type, right_type]
        when %i[type_int type_int], %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
          [:type_bool, left_value < right_value]
        when %i[type_string type_string]
          [:type_bool, left_value < right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_smalleroreq # <=
        case [left_type, right_type]
        when %i[type_int type_int], %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
          [:type_bool, left_value <= right_value]
        when %i[type_string type_string]
          [:type_bool, left_value <= right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_eq # ==
        case [left_type, right_type]
        when %i[type_int type_int], %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
          [:type_bool, left_value == right_value]
        when %i[type_string type_string]
          [:type_bool, left_value == right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      elsif node.op.token_type == :tok_noteq # !=
        case [left_type, right_type]
        when %i[type_int type_int], %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
          [:type_bool, left_value != right_value]
        when %i[type_string type_string]
          [:type_bool, left_value != right_value]
        else
          runtime_error(left_value, right_value, node)
        end
      end

    elsif node.is_a? UnOp
      operand_type, operand_value = interpret!(node.operand, env)

      if node.op.token_type == :tok_plus
        case operand_type
        when :type_int
          [:type_int, +operand_value]
        when :type_float
          [:type_float, +operand_value]
        else
          runtime_error_unop(operand_value, node)
        end
      elsif node.op.token_type == :tok_minus
        case operand_type
        when :type_int
          [:type_int, -operand_value]
        when :type_float
          [:type_float, -operand_value]
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
      # handle arrays display
      if expression_type == :type_array
        formatted_value = format_array_value(expression_value)
        print("#{formatted_value} ")
      else
        print("#{expression_value} ")
      end

    elsif node.is_a? PrintlnStmt
      expression_type, expression_value = interpret!(node.value, env)
      # handle arrays display
      if expression_type == :type_array
        formatted_value = format_array_value(expression_value)
        p(formatted_value)
      else
        puts(expression_value)
      end

    elsif node.is_a? IfStmt
      test_type, test_value = interpret!(node.test, env)
      # TODO: export it to a general private method
      # TODO: use the same type of testing conditions just like in JS (nil, false and 0 would not pass only)
      Utils.runtime_error("Condition type #{test_value} is not a boolean", node.op.line) unless test_type == :type_bool

      if test_value
        interpret!(node.then_stmt, env.new_env)
      else
        # check else-if statements (albojesli)
        executed = false
        node.else_if_conditions.each do |condition|
          else_if_test, else_if_stmt = condition
          else_if_type, else_if_value = interpret!(else_if_test, env)
          Utils.runtime_error('Else-if condition must be boolean', node.line) unless else_if_type == :type_bool

          next unless else_if_value

          interpret!(else_if_stmt, env.new_env)
          executed = true
          break
        end

        # if no other condition was fullfiled, execute else (albo) statement
        interpret!(node.else_stmt, env.new_env) if !executed && node.else_stmt
      end
    elsif node.is_a? OneLinerIfStmt
      test_type, test_value = interpret!(node.test, env)
      Utils.runtime_error('Condition must be boolean', node.line) unless test_type == :type_bool

      interpret!(node.then_stmt, env) if test_value

    elsif node.is_a? BreakLoop
      raise BreakException.new
    elsif node.is_a? ContinueLoop
      raise ContinueException.new

    elsif node.is_a? WhileStmt
      # Create a new environment for the while loop scope
      loop_env = env.new_env

      while true
        # Evaluate test condition in the parent environment
        test_type, test_value = interpret!(node.test, env)

        # Validate the test condition type
        Utils.runtime_error('While test is not a boolean expression', node.line) if test_type != :type_bool

        # Exit loop if condition is false
        break unless test_value

        # Execute body in the loop's environment
        begin
          interpret!(node.body_statement, loop_env)
        rescue ContinueException
          next
        rescue BreakException
          break
        end
      end
    elsif node.is_a? LoopStmt
      loop_env = env.new_env
      while true
        # Execute body in the loop's environment
        begin
          interpret!(node.body_statement, loop_env)
        rescue ContinueException
          next
        rescue BreakException
          break
        end
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
          begin
            loop_env.set_var(var_name, index_value, :type_int)
            interpret!(node.body_statement, loop_env)
          rescue ContinueException
          rescue BreakException
            break
          end
          index_value += step
        end
      else
        if node.step_statement.nil?
          step = -1
        else
          step_type, step = interpret!(node.step_statement, env)
        end
        while index_value >= end_value
          begin
            loop_env.set_var(var_name, index_value, :type_int)
            interpret!(node.body_statement, loop_env)
          rescue ContinueException
          rescue BreakException
            break
          end
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
        new_func_env.set_local_var(param.name, argval[1], argval[0])
      end

      # interpret function declaration body, wrap in into a rescue block to catch a return statement
      begin
        interpret!(func_declr.body_statement, new_func_env)
      rescue ReturnError => e
        e.value
      end
    elsif node.is_a? FuncCallStmt
      interpret!(node.expression, env)
    elsif node.is_a? ArrayLiteral
      elements = []

      # interpret each element of the array
      node.elements.each do |element|
        element_type, element_value = interpret!(element, env)
        elements << {
          type: element_type,
          value: element_value
        }
      end

      [:type_array, elements]
    elsif node.is_a? ArrayAccess
      array_var = env.get_var(node.array.name)
      unless array_var[:type] == :type_array
        Utils.runtime_error("Variable #{node.array.name} is not an array",
                            node.line)
      end

      index_type, index_value = interpret!(node.index, env)
      Utils.runtime_error('Array index must be an integer', node.line) unless index_type == :type_int

      array = array_var[:value]
      if index_value <= -array.length || index_value >= array.length
        Utils.runtime_error('Array index out of bounds',
                            node.line)
      end

      [array[index_value][:type], array[index_value][:value]]
    elsif node.is_a? ArrayAccessStmt
      interpret!(node.expression, env)
    elsif node.is_a? ArrayAssignment
      # interpret entire array first
      if node.array.is_a?(ArrayAccess)
        array_type, array_value = interpret!(node.array, env)
      else
        array_var = env.get_var(node.array.name)
        unless array_var[:type] == :type_array
          Utils.runtime_error("Variable #{node.array.name} is not an array",
                              node.line)
        end
        array_type = array_var[:type]
        array_value = array_var[:value]
      end

      index_type, index_value = interpret!(node.index, env)
      Utils.runtime_error('Array index must be an integer', node.line) unless index_type == :type_int
      Utils.runtime_error('Index out of bounds', node.line) if index_value < 0 || index_value >= array_value.length

      value_type, value = interpret!(node.value, env)
      array_value[index_value] = { type: value_type, value: value }

      # if it's a nested access, update main array
      if node.array.is_a?(ArrayAccess)
        parent_array = env.get_var(node.array.array.name)
        parent_index_type, parent_index_value = interpret!(node.array.index, env)
        parent_array[:value][parent_index_value] = { type: :type_array, value: array_value }
      end

      # save new value in local environment
      if node.array.is_a?(ArrayAccess)
        env.set_var(node.array.array.name, parent_array[:value], :type_array)
      else
        env.set_var(node.array.name, array_value, :type_array)
      end

    elsif node.is_a? ArrayAssignmentStmt
      interpret!(node.expression, env)
    elsif node.is_a? ObjectLiteral
      pairs = {}
      node.pairs.each do |key, value_expr|
        value_type, value = interpret!(value_expr, env)
        pairs[key] = { type: value_type, value: value }
      end

      [:type_object, pairs]
    elsif node.is_a? ObjectAccess
      object_var = env.get_var(node.object.name)
      unless object_var[:type] == :type_object
        Utils.runtime_error("Variable #{node.object.name} is not an object",
                            node.line)
      end

      key_type, key_value = interpret!(node.key, env)
      Utils.runtime_error('Object key must be a string', node.line) unless key_type == :type_string

      value = object_var[:value][key_value]
      Utils.runtime_error("Undefined key #{key_value}", node.line) unless value

      [value[:type], value[:value]]

    elsif node.is_a? ObjectAssignment
      object_var = env.get_var(node.object.name)
      unless object_var[:type] == :type_object
        Utils.runtime_error("Variable #{node.object.name} is not an object",
                            node.line)
      end

      key_type, key_value = interpret!(node.key, env)
      Utils.runtime_error('Object key must be a string', node.line) unless key_type == :type_string

      value_type, value = interpret!(node.value, env)
      object_var[:value][key_value] = { type: value_type, value: value }

      # save edited value in env
      env.set_var(node.object.name, object_var[:value], :type_object)

      [value_type, value]
    elsif node.is_a? MethodCall
      # Najpierw interpretujemy obiekt na którym wywoływana jest metoda
      object_type, object_value = interpret!(node.object, env)
      Utils.runtime_error('Cannot call method on undefined object', node.line) unless object_value

      # evaluate all arguments of method
      evaluated_args = node.arguments.map { |arg| interpret!(arg, env)[1] }

      # # Pobieramy typ obiektu i wywołujemy odpowiednią metodę z environment
      # object_type = object_var[:type]
      # object_value = object_var[:value]

      begin
        result = env.call_method(object_type, node.method_name, object_value, evaluated_args, node.line)

        # Określamy typ zwracanej wartości
        result_type = case result
                      when Integer then :type_int
                      when Float then :type_float
                      when String then :type_string
                      when TrueClass, FalseClass then :type_bool
                      when Array then :type_array
                      when NilClass then :type_null
                      else
                        Utils.runtime_error("Unexpected return type from method #{node.method_name}", node.line)
                      end

        [result_type, result]
      rescue StandardError => e
        Utils.runtime_error("Error executing method #{node.method_name}: #{e.message}", node.line)
      end
    elsif node.is_a? MethodCallStmt
      interpret!(node.expression, env)
    elsif node.is_a? ExpressionStmt
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

  # TODO: move it to other file on utils
  def format_array_value(value)
    if value.is_a?(Array)
      value.map do |elem|
        if elem.is_a?(Hash)
          if elem[:type] == :type_array
            format_array_value(elem[:value])
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
end

# TODO: export this to another file
class ReturnError < StandardError
  attr_reader :value

  def initialize(value)
    @value = value
    super()
  end
end

class BreakException < StandardError; end
class ContinueException < StandardError; end
