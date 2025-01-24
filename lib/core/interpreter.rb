# frozen_string_literal: true

module Core
  class Interpreter
    BOOL_TRUE = 'prawda'
    BOOL_FALSE = 'falsz'

    def init
    end

    def interpret!(node, env)
      if node.is_a? AST::Int
        [:type_int, node.value.to_i]
      elsif node.is_a? AST::Flt
        [:type_float, node.value.to_f]
      elsif node.is_a? AST::Str
        [:type_string, node.value.to_s]
      elsif node.is_a? AST::Bool
        [:type_bool, node.value]
      elsif node.is_a? AST::Null
        [:type_null, 'nic']
      elsif node.is_a? AST::Grouping
        interpret!(node.value, env)
      elsif node.is_a? AST::Identifier
        # check if it's a variable
        var_raw = env.get_var(node.name)

        if var_raw.nil?
          # if not a var, check if it's a function call
          func = env.get_func(node.name)
          return [:type_function, { declaration: func[0], env: func[1] }] if func

          Utils.runtime_error("Undeclared identifier #{node.name}", node.line)
        end

        Utils.runtime_error("Uninitialized identifier #{node.name}", node.line) if var_raw[:type].nil?
        [var_raw[:type], var_raw[:value]]
      elsif node.is_a? AST::Assignment
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
      elsif node.is_a? AST::AssignmentExpr
        var = env.get_var(node.left.name)
        if var.nil?
          Utils.runtime_error("Variable #{node.left.name} must be declared with 'niech' before assignment", node.line)
        elsif var[:constant]
          Utils.runtime_error("Variable #{node.left.name} is constant and cannot be mutated", node.line)
        end

        # evaluate right side of the expression
        right_type, right_value = interpret!(node.right, env)
        # assign new value and overwrite existing one
        env.set_var(node.left.name, right_value, right_type)
        [right_type, right_value]
      elsif node.is_a? AST::VariableDeclaration
        right_type, right_value = interpret!(node.right, env)
        # declare new variable
        var_name = node.left.name
        is_constant = var_name.match?(/^[A-Z_]+$/) # declare as constant if CAPITALIZED

        env.set_local_var(var_name, right_value, right_type, is_constant)
      elsif node.is_a? AST::GlobalVariableDeclaration
        global_env = env.get_global_env

        right_type, right_value = interpret!(node.right, env)

        # declare new variable in global scope
        global_env.set_local_var(node.left.name, right_value, right_type)
      elsif node.is_a? AST::BinOp

        left_type, left_value = interpret!(node.left, env)
        right_type, right_value = interpret!(node.right, env)

        # handle operations with null values
        if left_type == :type_null || right_type == :type_null
          case node.op.token_type
          when :tok_eq # ==
            return [:type_bool, to_bool_value(left_type == right_type)]
          when :tok_noteq # !=
            return [:type_bool, to_bool_value(left_type != right_type)]
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
            [:type_bool, to_bool_value(left_value > right_value)]
          when %i[type_string type_string]
            [:type_bool, to_bool_value(left_value > right_value)]
          else
            runtime_error(left_value, right_value, node)
          end
        elsif node.op.token_type == :tok_greateroreq # >=
          case [left_type, right_type]
          when %i[type_int type_int], %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
            [:type_bool, to_bool_value(left_value >= right_value)]
          when %i[type_string type_string]
            [:type_bool, to_bool_value(left_value >= right_value)]
          else
            runtime_error(left_value, right_value, node)
          end
        elsif node.op.token_type == :tok_smaller # <
          case [left_type, right_type]
          when %i[type_int type_int], %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
            [:type_bool, to_bool_value(left_value < right_value)]
          when %i[type_string type_string]
            [:type_bool, to_bool_value(left_value < right_value)]
          else
            runtime_error(left_value, right_value, node)
          end
        elsif node.op.token_type == :tok_append # <<
          if left_type == :type_array
            left_value << { type: right_type, value: right_value }
            env.set_var(node.left.name, left_value, left_type)
            [:type_array, left_value]
          else
            Utils.runtime_error('Operator << can only be used with arrays', node.line)
          end
        elsif node.op.token_type == :tok_smalleroreq # <=
          case [left_type, right_type]
          when %i[type_int type_int], %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
            [:type_bool, to_bool_value(left_value <= right_value)]
          when %i[type_string type_string]
            [:type_bool, to_bool_value(left_value <= right_value)]
          else
            runtime_error(left_value, right_value, node)
          end
        elsif node.op.token_type == :tok_eq # ==
          case [left_type, right_type]
          when %i[type_int type_int], %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
            [:type_bool, to_bool_value(left_value == right_value)]
          when %i[type_string type_string]
            [:type_bool, to_bool_value(left_value == right_value)]
          else
            runtime_error(left_value, right_value, node)
          end
        elsif node.op.token_type == :tok_noteq # !=
          case [left_type, right_type]
          when %i[type_int type_int], %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
            [:type_bool, to_bool_value(left_value != right_value)]
          when %i[type_string type_string]
            [:type_bool, to_bool_value(left_value != right_value)]
          else
            runtime_error(left_value, right_value, node)
          end
        end

      elsif node.is_a? AST::UnOp
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
            [:type_bool, to_bool_value(!from_bool_value(operand_value))]
          elsif operand_type == :type_null
            [:type_bool, BOOL_TRUE] # !nic returns true
          else
            runtime_error_unop(operand_value, node)
          end
        end

      # short-circut evaluation for logical operators, left 'and' is false => false, left 'or' is true => true
      # otherwise search for the right side
      elsif node.is_a? AST::LogicalOp
        left_type, left_value = interpret!(node.left, env)

        if node.op.token_type == :tok_or
          return [left_type, left_value] if left_value == BOOL_TRUE
        elsif node.op.token_type == :tok_and
          return [left_type, left_value] if left_value == BOOL_FALSE || left_type == :type_null
        end

        return interpret!(node.right, env) unless node.right.is_a?(AST::Assignment)

        # if right side is an assignment, eg: falsz i x = 10
        right_type, right_value = interpret!(node.right.right, env)
        env.set_var(node.right.left.name, right_value, right_type)
        [right_type, right_value]
      elsif node.is_a? AST::Stmts
        i = 0
        while i < node.stmts.size
          interpret!(node.stmts[i], env)
          i += 1
        end
      elsif node.is_a? AST::CompoundAssignment
        var = env.get_var(node.left.name)
        Utils.runtime_error("Undefined variable #{node.left.name}", node.line) unless var
        Utils.runtime_error("Variable #{node.left.name} is constant and cannot be mutated", node.line) if var[:constant]

        right_type, right_value = interpret!(node.right, env)

        # calculate new value depending on operator type
        new_value = case node.operator.token_type
                    when :tok_pluseq
                      var[:value] + right_value
                    when :tok_minuseq
                      var[:value] - right_value
                    when :tok_stareq
                      var[:value] * right_value
                    when :tok_slasheq
                      Utils.runtime_error('Division by zero', node.line) if right_value == 0
                      var[:value] / right_value
                    end

        # atcualise variable in current environment
        env.set_var(node.left.name, new_value, var[:type])

        # [var[:type], new_value]
      elsif node.is_a? AST::PrintStmt
        expression_type, expression_value = interpret!(node.value, env)
        formatted_value = format_value(expression_type, expression_value)
        print("#{formatted_value} ")

      elsif node.is_a? AST::PrintlnStmt
        expression_type, expression_value = interpret!(node.value, env)
        formatted_value = format_value(expression_type, expression_value) # handle arrays and objects
        p(formatted_value)

      elsif node.is_a? AST::IfStmt
        test_type, test_value = interpret!(node.test, env)

        if is_truthy?(test_type, test_value)
          interpret!(node.then_stmt, env.new_env)
        else
          # check else-if statements
          executed = false
          node.else_if_conditions.each do |condition|
            else_if_test, else_if_stmt = condition
            else_if_type, else_if_value = interpret!(else_if_test, env)

            next unless is_truthy?(else_if_type, else_if_value)

            interpret!(else_if_stmt, env.new_env)
            executed = true
            break
          end
          # if no other condition was fullfiled, execute else (albo) statement
          interpret!(node.else_stmt, env.new_env) if !executed && node.else_stmt
        end

      elsif node.is_a? AST::OneLinerIfStmt
        test_type, test_value = interpret!(node.test, env)
        interpret!(node.then_stmt, env) if is_truthy?(test_type, test_value)

      elsif node.is_a? AST::BreakLoop
        raise BreakException.new
      elsif node.is_a? AST::ContinueLoop
        raise ContinueException.new

      elsif node.is_a? AST::WhileStmt
        # Create a new environment for the while loop scope
        loop_env = env.new_env

        while true
          # Evaluate test condition in the parent environment
          test_type, test_value = interpret!(node.test, env)

          # Validate the test condition type
          Utils.runtime_error('While test is not a boolean expression', node.line) if test_type != :type_bool

          # Exit loop if condition is false
          break unless test_value == BOOL_TRUE

          # Execute body in the loop's environment
          begin
            interpret!(node.body_statement, loop_env)
          rescue ContinueException
            next
          rescue BreakException
            break
          end
        end
      elsif node.is_a? AST::LoopStmt
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
      elsif node.is_a? AST::ForStmt
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
          while to_bool_value(index_value < end_value) == BOOL_TRUE
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
          while to_bool_value(index_value > end_value) == BOOL_TRUE
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
      elsif node.is_a? AST::ForInObjectStmt
        object_type, object_value = interpret!(node.object, env)
        Utils.runtime_error('Can only iterate over objects', node.line) unless object_type == :type_object

        loop_env = env.new_env

        object_value.each do |key, value|
          # always set key (it's required)
          loop_env.set_var(node.key_identifier.name, key, :type_string)

          # setting value is optional
          loop_env.set_var(node.value_identifier.name, value[:value], value[:type]) if node.value_identifier

          interpret!(node.body_statement, loop_env)
        rescue BreakException
          break
        rescue ContinueException
          next
        end
      elsif node.is_a? AST::ForInArrayStmt
        array_type, array_value = interpret!(node.array, env)
        Utils.runtime_error('Can only iterate over arrays', node.line) unless array_type == :type_array

        loop_env = env.new_env

        array_value.each do |element|
          # set values in env
          if element.is_a?(Hash)
            loop_env.set_var(node.element_identifier.name, element[:value], element[:type])
          else
            loop_env.set_var(node.element_identifier.name, element, get_type(element))
          end

          interpret!(node.body_statement, loop_env)
        rescue BreakException
          break
        rescue ContinueException
          next
        end
      elsif node.is_a? AST::FuncDclr
        # store entire parsed 'body' of the function with its current env
        env.set_func(node.name, [node, env]) # TODO: improve memory management here
      elsif node.is_a? AST::FuncCall
        env.increment_call_depth(node.line)  # increase stack depth to avoid too big recursion
        begin
          var = env.get_var(node.name)

          if var && !validate_function_value(var)
            Utils.runtime_error("Invalid function value for #{node.name}",
                                node.line)
          end

          if var && var[:type] == :type_function
            # if it's a variable containing function
            func_declr = var[:value][:declaration]
            func_env = var[:value][:env]
          else
            # if not, just check for a regulat function
            func = env.get_func(node.name)
            Utils.runtime_error("Function #{node.name} was not declared in current scope", node.line) unless func
            # fetch function declaration
            func_declr = func[0] # entire func declaration
            func_env   = func[1] # function env
          end

          # check if number of args matches expected number of params in func delcaration
          if func_declr.params.size != node.arguments.size
            Utils.runtime_error(
              "Function #{node.name} expected #{func_declr.params.size} arguments, got #{node.arguments.size} instead", node.line
            )
          end

          # evalate args
          arguments = node.arguments.map do |arg|
            if arg.is_a?(AST::Identifier)
              # try to fetch it as a variable
              var = env.get_var(arg.name)
              if var
                [var[:type], var[:value]]
              else
                # if var not found, try to fetch a function
                func_value = env.get_func_as_value(arg.name)
                Utils.runtime_error("Undefined variable or function #{arg.name}", arg.line) unless func_value
                func_value
              end
            else
              interpret!(arg, env)
            end
          end
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
            result || [:type_null, 'nic'] # return 'nic' if function does not return any value with direct return 'zwroc' statement
          rescue ReturnError => e
            e.value
          end
        ensure
          env.decrement_call_depth
        end
      elsif node.is_a? AST::FuncCallStmt
        interpret!(node.expression, env)
      elsif node.is_a? AST::ArrayLiteral
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
      elsif node.is_a? AST::ArrayAccessStmt
        interpret!(node.expression, env)
      elsif node.is_a? AST::ObjectOrArrayAccessStmt
        interpret!(node.expression, env)
      elsif node.is_a? AST::ObjectLiteral
        pairs = {}
        node.pairs.each do |key, value_expr|
          value_type, value = interpret!(value_expr, env)
          pairs[key] = { type: value_type, value: value }
        end

        [:type_object, pairs]
      elsif node.is_a? AST::ObjectOrArrayAccess
        if node.array.is_a?(AST::Identifier)
          object_var = env.get_var(node.array.name)
        else
          type, value = interpret!(node.array, env)
          object_var = { type: type, value: value }
        end

        key_type, key_value = interpret!(node.index, env)

        case object_var[:type]
        when :type_array
          Utils.runtime_error('Array index must be an integer', node.line) unless key_type == :type_int
          length = object_var[:value].length
          Utils.runtime_error('Index out of bounds', node.line) if key_value >= length || key_value < -length

          element = object_var[:value][key_value]
          [element[:type], element[:value]]
        when :type_object
          Utils.runtime_error('Object key must be a string', node.line) unless key_type == :type_string
          value = object_var[:value][key_value]
          Utils.runtime_error("Undefined key #{key_value}", node.line) unless value
          [value[:type], value[:value]]
        else
          Utils.runtime_error("Expression #{get_access_path(node, env)} is neither array nor object", node.line)
        end
      elsif node.is_a? AST::ObjectOrArrayAssignment
        if node.array.is_a?(AST::Identifier)
          object_var = env.get_var(node.array.name)
          Utils.runtime_error("Undefined variable #{get_access_path(node, env)}", node.line) unless object_var
        else
          type, value = interpret!(node.array, env)
          object_var = { type: type, value: value }
        end

        key_type, key_value = interpret!(node.index, env)
        value_type, value = interpret!(node.value, env)

        case object_var[:type]
        when :type_array
          Utils.runtime_error('Array index must be an integer', node.line) unless key_type == :type_int
          length = object_var[:value].length
          Utils.runtime_error('Index out of bounds', node.line) if key_value >= length || key_value < -length

          object_var[:value][key_value] = { type: value_type, value: value }
        when :type_object
          Utils.runtime_error('Object key must be a string', node.line) unless key_type == :type_string
          object_var[:value][key_value] = { type: value_type, value: value }
        else
          Utils.runtime_error("Expression #{get_access_path(node, env)} is neither array nor object", node.line)
        end

        # actualize var in env for a direct access only
        env.set_var(node.array.name, object_var[:value], object_var[:type]) if node.array.is_a?(AST::Identifier)

        [value_type, value]
      elsif node.is_a? AST::MethodCall
        # first interpret object
        object_type, object_value = interpret!(node.object, env)
        Utils.runtime_error('Cannot call method on undefined object', node.line) unless object_value

        # evaluate all arguments of method
        evaluated_args = node.arguments.map { |arg| interpret!(arg, env)[1] }

        # fetch object type and call a proper method from env
        # object_type = object_var[:type]
        # object_value = object_var[:value]

        begin
          result = env.call_method(object_type, node.method_name, object_value, evaluated_args, node.line)

          # set type of the returned value
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
      elsif node.is_a? AST::MethodCallStmt
        interpret!(node.expression, env)
      elsif node.is_a? AST::ExpressionStmt
        interpret!(node.expression, env)
      elsif node.is_a? AST::ReturnStatement
        raise ReturnError.new(interpret!(node.value, env))
      elsif node.is_a? AST::ExitStmt
        if node.code
          exit(node.code.value)
        else
          exit
        end
      elsif node.is_a? AST::Input
        if node.prompt
          prompt_type, prompt_value = interpret!(node.prompt, env)
          puts(prompt_value)
        end

        input = STDIN.gets
        input = input.chomp if input

        [:type_string, input]
      elsif node.is_a? AST::InputStmt
        interpret!(node.expression, env)
      end
    end

    # entry point of interpreter creating brand new global/parent environment
    def interpret_ast(node)
      env = Environment.new
      interpret!(node, env)
    end

    private

    def runtime_error(left_value, right_value, node)
      Utils.runtime_error("Unsupported operator #{node.op.lexeme} between #{left_value} and #{right_value}",
                          node.op.line)
    end

    def runtime_error_unop(value, node)
      Utils.runtime_error("Unsupported operator #{node.op.lexeme} with #{value}", node.op.line)
    end

    def validate_function_value(val)
      return false unless val && val[:type] == :type_function
      return false unless val[:value] && val[:value][:declaration] && val[:value][:env]

      true
    end

    def is_truthy?(type, value)
      case type
      when :type_bool
        value == BOOL_TRUE
      when :type_null
        false
      else
        Utils.runtime_error('Condition must be boolean or null', line)
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

    def to_bool_value(ruby_bool)
      ruby_bool ? BOOL_TRUE : BOOL_FALSE
    end

    def from_bool_value(string_bool)
      string_bool == BOOL_TRUE
    end

    # TODO: move it to other file on utils
    def format_value(type, value)
      case type
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
        "#{key}: #{formatted}" # usuwamy dodatkowe \"
      end
      "{#{pairs.join(', ')}}"
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
end
