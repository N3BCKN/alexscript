# frozen_string_literal: true

module AlexScript
  module Core
    class Interpreter
      BOOL_TRUE = 'prawda'
      BOOL_FALSE = 'falsz'

      def initialize
        @import_manager = Utils::ImportManager.new
        @current_file = 'main'
        @exception_registry = {}

        @exception_registry['WyjatekPodstawowy'] = Utils::WyjatekPodstawowy
        @exception_registry['BladWykonania'] = Utils::BladWykonania
        @exception_registry['BladSkladni'] = Utils::BladSkladni
        @exception_registry['BladTypu'] = Utils::BladTypu
        @exception_registry['BladZakresu'] = Utils::BladZakresu
        @exception_registry['BladArgumentu'] = Utils::BladArgumentu
        @exception_registry['BladNazwy'] = Utils::BladNazwy
      end

      def set_current_file(file)
        @current_file = file
        Utils::ContextTracker.current_file = file
      end

      def interpret!(node, env)
        Utils::ContextTracker.current_line = node.line if node.respond_to?(:line) # always set line first

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

            Utils.runtime_error("Niezadeklarowany identyfikator #{node.name}")
          end

          Utils.runtime_error("Niezainicjowany identyfikator #{node.name}") if var_raw[:type].nil?
          [var_raw[:type], var_raw[:value]]
        elsif node.is_a? AST::Assignment
          var = env.get_var(node.left.name)
          if var.nil?
            Utils.runtime_error("Zmienna #{node.left.name} musi byc zadeklarowana z 'niech' przed przypisaniem")
          elsif var[:constant]
            Utils.runtime_error("Zmienna #{node.left.name} jest stala i nie moze byc zmieniana")
          end

          # evaluate right side of the expression
          right_type, right_value = interpret!(node.right, env)
          # assign new value or overwrite existing one
          env.set_var(node.left.name, right_value, right_type)
        elsif node.is_a? AST::AssignmentExpr
          var = env.get_var(node.left.name)
          if var.nil?
            Utils.runtime_error("Zmienna #{node.left.name} musi byc zadeklarowana z 'niech' przed przypisaniem")
          elsif var[:constant]
            Utils.runtime_error("Zmienna #{node.left.name} jest stala i nie moze byc zmieniana")
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
            when %i[type_string type_array]
              [:type_string, left_value + format_array_value(right_value).to_s]
            when %i[type_array type_string]
              [:type_string, format_array_value(left_value).to_s + right_value]
            when %i[type_string type_object]
              [:type_string, left_value + format_object_value(right_value).to_s]
            when %i[type_object type_string]
              [:type_string, format_object_value(left_value).to_s + right_value]
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
            Utils.runtime_error('Dzielenie przez zero', node.op.line) if right_value == 0

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
              Utils.runtime_error('Operator << moze byc uzyty tylko z tablicami')
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
          Utils.runtime_error("Niezdefiniowana zmienna #{node.left.name}") unless var
          Utils.runtime_error("Zmienna #{node.left.name} jest stala i nie moze byc zmieniana") if var[:constant]

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
                        Utils.runtime_error('Dzielenie przez zero') if right_value == 0
                        var[:value] / right_value
                      end

          # update variable in current environment
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

          if is_truthy?(test_type, test_value, node.line)
            interpret!(node.then_stmt, env.new_env)
          else
            # check else-if statements
            executed = false
            node.else_if_conditions.each do |condition|
              else_if_test, else_if_stmt = condition
              else_if_type, else_if_value = interpret!(else_if_test, env)

              next unless is_truthy?(else_if_type, else_if_value, node.line)

              interpret!(else_if_stmt, env.new_env)
              executed = true
              break
            end
            # if no other condition was fullfiled, execute else (albo) statement
            interpret!(node.else_stmt, env.new_env) if !executed && node.else_stmt
          end

        elsif node.is_a? AST::OneLinerIfStmt
          test_type, test_value = interpret!(node.test, env)
          interpret!(node.then_stmt, env) if is_truthy?(test_type, test_value, node.line)

        elsif node.is_a? AST::BreakLoop
          raise Utils::BreakException.new
        elsif node.is_a? AST::ContinueLoop
          raise Utils::ContinueException.new

        elsif node.is_a? AST::WhileStmt
          # Create a new environment for the while loop scope
          loop_env = env.new_env

          while true
            # Evaluate test condition in the parent environment
            test_type, test_value = interpret!(node.test, env)

            # Validate the test condition type
            Utils.runtime_error('Test while nie jest wyrazeniem boolowskim') if test_type != :type_bool

            # Exit loop if condition is false
            break unless test_value == BOOL_TRUE

            # Execute body in the loop's environment
            begin
              interpret!(node.body_statement, loop_env)
            rescue Utils::ContinueException
              next
            rescue Utils::BreakException
              break
            end
          end
        elsif node.is_a? AST::LoopStmt
          loop_env = env.new_env
          while true
            # Execute body in the loop's environment
            begin
              interpret!(node.body_statement, loop_env)
            rescue Utils::ContinueException
              next
            rescue Utils::BreakException
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
              rescue Utils::ContinueException
              rescue Utils::BreakException
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
              rescue Utils::ContinueException
              rescue Utils::BreakException
                break
              end
              index_value += step
            end
          end
        elsif node.is_a? AST::ForInObjectStmt
          object_type, object_value = interpret!(node.object, env)
          Utils.runtime_error('Moze iterowac tylko po obiektach') unless object_type == :type_object

          loop_env = env.new_env

          object_value.each do |key, value|
            # always set key (it's required)
            loop_env.set_var(node.key_identifier.name, key, :type_string)

            # setting value is optional
            loop_env.set_var(node.value_identifier.name, value[:value], value[:type]) if node.value_identifier

            interpret!(node.body_statement, loop_env)
          rescue Utils::BreakException
            break
          rescue Utils::ContinueException
            next
          end
        elsif node.is_a? AST::ForInArrayStmt
          array_type, array_value = interpret!(node.array, env)
          Utils.runtime_error('Moze iterowac tylko po tablicach') unless array_type == :type_array

          loop_env = env.new_env

          array_value.each do |element|
            # set values in env
            if element.is_a?(Hash)
              loop_env.set_var(node.element_identifier.name, element[:value], element[:type])
            else
              loop_env.set_var(node.element_identifier.name, element, get_type(element)) # TODO: FIX THIS MISSING get_type METHOD ASAP
            end

            interpret!(node.body_statement, loop_env)
          rescue Utils::BreakException
            break
          rescue Utils::ContinueException
            next
          end
        elsif node.is_a? AST::FuncDclr
          # store entire parsed 'body' of the function with its current env
          env.set_func(node.name, [node, env]) # TODO: improve memory management here
				elsif node.is_a? AST::FuncCall
					env.increment_call_depth(node.line)
					begin
						# new code: first check if we're in a class instance context
						current_instance = env.get_instance
						class_method_called = false
						
						if current_instance
							# we're in an instance method - first look for method in current class
							# then in base classes (including private ones)
							
							# initialize variables to store found method
							method_info = nil
							found_class_def = nil
							
							# start from current class
							current_class_name = current_instance[:class_name]
							
							# go through class hierarchy searching for method
							while current_class_name && !method_info
								current_class_def = env.get_class(current_class_name)
								break unless current_class_def
								
								# check if method exists in this class
								if current_class_def[:methods] && current_class_def[:methods][node.name]
									method_info = current_class_def[:methods][node.name]
									found_class_def = current_class_def
									break
								end
								
								# move to base class
								current_class_name = current_class_def[:parent]
							end
							
							if method_info
								class_method_called = true
								# this is a method call from class hierarchy (can be private)
								
								# evaluate arguments
								arguments = node.arguments.map do |arg|
									if arg.is_a?(AST::Identifier)
										var = env.get_var(arg.name)
										if var
											[var[:type], var[:value]]
										else
											func_value = env.get_func_as_value(arg.name)
											Utils.runtime_error("Niezdefiniowana zmienna lub funkcja #{arg.name}", arg.line) unless func_value
											func_value
										end
									else
										interpret!(arg, env)
									end
								end
								
								# handle parameters, similar to regular functions
								func_declr = method_info[:declaration]
								func_env = method_info[:env]
								
								# rest type parameters
								rest_param = func_declr.params.find(&:rest?)
								min_args = func_declr.params.count { |p| !p.has_default? && !p.rest? }
								max_args = rest_param ? Float::INFINITY : func_declr.params.size
								
								# validate argument count
								if node.arguments.size < min_args
									Utils.runtime_error(
										"Metoda #{node.name} oczekiwala minimum #{min_args} argumentów, otrzymała #{node.arguments.size}"
									)
								end
								
								unless rest_param
									if node.arguments.size > max_args
										Utils.runtime_error(
											"Metoda #{node.name} oczekiwala maksymalnie #{max_args} argumentów, otrzymała #{node.arguments.size}"
										)
									end
								end
								
								# create new environment for method
								new_func_env = func_env.new_env
								new_func_env.set_instance(current_instance)
								
								# handle regular parameters
								rest_idx = func_declr.params.index(&:rest?)
								rest_position = rest_idx || func_declr.params.size
								
								normal_params = func_declr.params.reject(&:rest?)
								normal_params.each_with_index do |param, idx|
									if idx < node.arguments.size && (rest_idx.nil? || idx < rest_idx)
										arg_val = arguments[idx]
										new_func_env.set_local_var(param.name, arg_val[1], arg_val[0])
									else
										if param.has_default?
											default_value = interpret!(param.default_value, func_env)
											new_func_env.set_local_var(param.name, default_value[1], default_value[0])
										else
											Utils.runtime_error("Brakujacy argument #{param.name}")
										end
									end
								end
								
								# handle rest parameter
								if rest_param
									rest_args = arguments[rest_position..-1] || []
									rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
									new_func_env.set_local_var(rest_param.name, rest_array_elements, :type_array)
								end
								
								# execute method body
								begin
									Utils::ContextTracker.track_method_call(node.name) do
										interpret!(func_declr.body_statement, new_func_env)
									end
									result = [:type_null, 'nic'] # return 'nic' if function does not return any value
								rescue Utils::ReturnError => e
									result = e.value
								end
							end
						end
						
						# end of new code - proceed to standard function handling
						# if no class method was found
						unless class_method_called
							var = env.get_var(node.name)
					
							Utils.runtime_error("Niepoprawna wartosc funkcji dla #{node.name}") if var && !validate_function_value(var)
					
							if var && var[:type] == :type_function
								# if it's a variable containing function
								func_declr = var[:value][:declaration]
								func_env = var[:value][:env]
							else
								# if not, just check for a regular function
								func = env.get_func(node.name)
								Utils.runtime_error("Funkcja #{node.name} nie zostala zadeklarowana w obecnym zakresie") unless func
								# fetch function declaration
								func_declr = func[0] # entire func declaration
								func_env   = func[1] # function env
							end
					
							# check if there is a rest (*args) param in funct call
							rest_param = func_declr.params.find(&:rest?)
							
							min_args = func_declr.params.count { |p| !p.has_default? && !p.rest? }
							max_args = rest_param ? Float::INFINITY : func_declr.params.size
							
							if node.arguments.size < min_args
								Utils.runtime_error(
									"Funkcja #{node.name} oczekiwala minimum #{min_args} argumentów, otrzymała #{node.arguments.size}"
								)
							end
							
							# check max number of args if rest param is not present 
							unless rest_param
								if node.arguments.size > max_args
									Utils.runtime_error(
										"Funkcja #{node.name} oczekiwala maksymalnie #{max_args} argumentów, otrzymała #{node.arguments.size}"
									)
								end
							end
					
							# evaluate args
							arguments = node.arguments.map do |arg|
								if arg.is_a?(AST::Identifier)
									# try to fetch it as a variable
									var = env.get_var(arg.name)
									if var
										[var[:type], var[:value]]
									else
										# if var not found, try to fetch a function
										func_value = env.get_func_as_value(arg.name)
										Utils.runtime_error("Niezdefiniowana zmienna lub funkcja #{arg.name}", arg.line) unless func_value
										func_value
									end
								else
									interpret!(arg, env)
								end
							end
					
							# new nested env for function
							new_func_env = func_env.new_env
					
							# index of the rest param
							rest_idx = func_declr.params.index(&:rest?)
							rest_position = rest_idx || func_declr.params.size
							
							# assign values to regular parameters (before rest parameter)
							normal_params = func_declr.params.reject(&:rest?)
							normal_params.each_with_index do |param, idx|
								if idx < node.arguments.size && (rest_idx.nil? || idx < rest_idx)
									# use passed argument
									arg_val = arguments[idx]
									new_func_env.set_local_var(param.name, arg_val[1], arg_val[0])
								else
									# use default value
									if param.has_default?
										default_value = interpret!(param.default_value, func_env)
										new_func_env.set_local_var(param.name, default_value[1], default_value[0])
									else
										Utils.runtime_error("Brakujacy argument #{param.name}")
									end
								end
							end
							
							# handle rest parameter if exists
							if rest_param
								rest_args = arguments[rest_position..-1] || []
								
								rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
								new_func_env.set_local_var(rest_param.name, rest_array_elements, :type_array)
							end
					
							# interpret function declaration body
							begin
								Utils::ContextTracker.track_method_call(node.name) do
									interpret!(func_declr.body_statement, new_func_env)
								end
								result = [:type_null, 'nic'] # return 'nic' if function does not return any value
							rescue Utils::ReturnError => e
								result = e.value
							end
						end
						
						result
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
            Utils.runtime_error('Indeks tablicy musi byc liczbą całkowitą') unless key_type == :type_int
            length = object_var[:value].length
            Utils.runtime_error('Indeks poza zakresem') if key_value >= length || key_value < -length

            element = object_var[:value][key_value]
            [element[:type], element[:value]]
          when :type_object
            Utils.runtime_error('Klucz obiektu musi byc ciagiem znakow') unless key_type == :type_string
            value = object_var[:value][key_value]
            Utils.runtime_error("Niezdefiniowany klucz #{key_value}") unless value
            [value[:type], value[:value]]
          else
            Utils.runtime_error("Wyrazenie #{get_access_path(node, env)} nie jest ani tablica ani obiektem", node.line)
          end
        elsif node.is_a? AST::ObjectOrArrayAssignment
          if node.array.is_a?(AST::Identifier)
            object_var = env.get_var(node.array.name)
            Utils.runtime_error("Niezdefiniowana zmienna #{get_access_path(node, env)}", node.line) unless object_var
          else
            type, value = interpret!(node.array, env)
            object_var = { type: type, value: value }
          end

          key_type, key_value = interpret!(node.index, env)
          value_type, value = interpret!(node.value, env)

          case object_var[:type]
          when :type_array
            Utils.runtime_error('Indeks tablicy musi byc liczbą całkowitą') unless key_type == :type_int
            length = object_var[:value].length
            Utils.runtime_error('Indeks poza zakresem') if key_value >= length || key_value < -length

            object_var[:value][key_value] = { type: value_type, value: value }
          when :type_object
            Utils.runtime_error('Klucz obiektu musi byc ciagiem znakow') unless key_type == :type_string
            object_var[:value][key_value] = { type: value_type, value: value }
          else
            Utils.runtime_error("Wyrazenie #{get_access_path(node, env)} nie jest ani tablica ani obiektem")
          end

          # update var in env for a direct access only
          env.set_var(node.array.name, object_var[:value], object_var[:type]) if node.array.is_a?(AST::Identifier)

          [value_type, value]
				elsif node.is_a? AST::MethodCall
					# interpret object
					object_type, object_value = interpret!(node.object, env)
				
					# check if this is a method call on a class (object is a class identifier)
					if node.object.is_a?(AST::Identifier) && env.get_class(node.object.name)
						class_name = node.object.name
						class_def = env.get_class(class_name)
						
						# first check if this is a built-in info method for class
						begin
							# prepare arguments
							evaluated_args = node.arguments.map { |arg| interpret!(arg, env)[1] }
							
							# add class name info to definition
							class_with_name = class_def.dup
							class_with_name[:name] = class_name
							
							# add environment access for methods that need it
							evaluated_args.unshift(env) if [:przodkowie, :czy_dziedziczy_po].include?(node.method_name.to_sym)
							
							# try to call built-in class method
							result = env.call_method(:type_class, node.method_name, class_with_name, evaluated_args)
							
							# determine result type
							result_type = case result
														when Integer then :type_int
														when Float then :type_float
														when String then :type_string
														when TrueClass, FalseClass then :type_bool
														when Array then :type_array
														when NilClass then :type_null
														when Hash then :type_object
														else
															:type_object # default treat as object
														end
							
							return [result_type, result]
						rescue StandardError => e
							# if no built-in method, continue with normal static methods
						end
						
						# look for static method in class hierarchy
						method_info = nil
						current_class_def = class_def
						
						while current_class_def && !method_info
							# check if method exists in current class
							if current_class_def[:static_methods] && current_class_def[:static_methods][node.method_name]
								method_info = current_class_def[:static_methods][node.method_name]
								break
							end
							
							# if not, check base class
							parent_name = current_class_def[:parent]
							break unless parent_name
							
							current_class_def = env.get_class(parent_name)
						end
						
						if method_info
							# handle static method call
							
							# evaluate arguments
							arguments = node.arguments.map { |arg| interpret!(arg, env) }
							
							# check argument count
							params = method_info[:declaration].params
							
							# handle rest type parameters
							rest_param = params.find(&:rest?)
							min_args = params.count { |p| !p.has_default? && !p.rest? }
							max_args = rest_param ? Float::INFINITY : params.size
							
							if arguments.size < min_args
								Utils.runtime_error(
									"Metoda statyczna #{node.method_name} oczekiwała minimum #{min_args} argumentów, otrzymała #{arguments.size}",
									node.line
								)
							end
							
							unless rest_param
								if arguments.size > max_args
									Utils.runtime_error(
										"Metoda statyczna #{node.method_name} oczekiwała maksymalnie #{max_args} argumentów, otrzymała #{arguments.size}",
										node.line
									)
								end
							end
							
							# create new environment for static method
							method_env = method_info[:env].new_env
							
							# assign arguments to parameters
							rest_idx = params.index(&:rest?)
							rest_position = rest_idx || params.size
							
							normal_params = params.reject(&:rest?)
							normal_params.each_with_index do |param, idx|
								if idx < arguments.size && (rest_idx.nil? || idx < rest_idx)
									method_env.set_local_var(param.name, arguments[idx][1], arguments[idx][0])
								elsif param.has_default?
									default_value = interpret!(param.default_value, method_info[:env])
									method_env.set_local_var(param.name, default_value[1], default_value[0])
								else
									Utils.runtime_error("Brakujący argument #{param.name}", node.line)
								end
							end
							
							# handle rest parameter
							if rest_param
								rest_args = arguments[rest_position..-1] || []
								rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
								method_env.set_local_var(rest_param.name, rest_array_elements, :type_array)
							end
							
							# execute static method body
							begin	
								Utils::ContextTracker.track_method_call(node.method_name) do
									interpret!(method_info[:declaration].body_statement, method_env)
								end
								result = [:type_null, 'nic']  # by default return 'nic'
							rescue Utils::ReturnError => e
								result = e.value  # or specific value returned by method
							end
							
							return result
						else
							Utils.runtime_error("Nieznana metoda statyczna '#{node.method_name}' w klasie #{class_name}", node.line)
						end
					end
				
					# handle class instance methods
					if object_type == :type_instance
						# find method in class hierarchy using optimized lookup
						method_result = env.find_method_in_hierarchy(object_value, node.method_name)
						Utils.runtime_error("Nieznana metoda #{node.method_name} dla instancji klasy #{object_value[:class_name]}", node.line) unless method_result
						
						method_info = method_result[:method_info]
						
						# check if method is private
						if method_info[:private]
							current_instance = env.get_instance
							same_instance = current_instance == object_value
							from_inside_class = current_instance && current_instance[:class_name] == object_value[:class_name]
							from_subclass = current_instance && env.is_subclass_of(current_instance[:class_name], object_value[:class_name])
							
							unless same_instance || from_inside_class || from_subclass
								Utils.runtime_error("Próba wywołania prywatnej metody #{node.method_name}", node.line)
							end
						end
															
						# evaluate arguments
						arguments = node.arguments.map { |arg| interpret!(arg, env) }
						
						# check argument count using preserved parameter information
						param_names = method_info[:param_names]
						param_defaults = method_info[:param_defaults]
						param_rest_flags = method_info[:param_rest_flags]
						
						has_rest = method_info[:has_rest]
						min_args = param_defaults.count(&:nil?) # params without defaults  
						max_args = has_rest ? Float::INFINITY : param_names.size
						
						if arguments.size < min_args
							Utils.runtime_error(
								"Metoda #{node.method_name} oczekiwała minimum #{min_args} argumentów, otrzymała #{arguments.size}",
								node.line
							)
						end
						
						unless has_rest
							if arguments.size > max_args
								Utils.runtime_error(
									"Metoda #{node.method_name} oczekiwała maksymalnie #{max_args} argumentów, otrzymała #{arguments.size}",
									node.line
								)
							end
						end
						
						# create new environment for method
						method_env = method_info[:env].new_env
						method_env.set_instance(object_value)
						
						# assign arguments to parameters using preserved names
						param_names.each_with_index do |param_name, idx|
							if idx < arguments.size && !param_rest_flags[idx]
								# regular parameter with provided argument
								method_env.set_local_var(param_name, arguments[idx][1], arguments[idx][0])
							elsif param_defaults[idx] && !param_rest_flags[idx]
								# parameter with default value
								default_value = interpret!(param_defaults[idx], env)
								method_env.set_local_var(param_name, default_value[1], default_value[0])
							elsif param_rest_flags[idx]
								# rest parameter - collect remaining arguments
								rest_args = arguments[idx..-1] || []
								rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
								method_env.set_local_var(param_name, rest_array_elements, :type_array)
								break # rest parameter is always last
							elsif param_defaults[idx].nil?
								Utils.runtime_error("Brakujący argument #{param_name}", node.line)
							end
						end
						
						# execute method body using preserved declaration
						begin
							Utils::ContextTracker.track_method_call(node.method_name) do
								interpret!(method_info[:declaration].body_statement, method_env)
							end
							result = [:type_null, 'nic']
						rescue Utils::ReturnError => e
							result = e.value
						end
						
						result
					else
						# keep existing handling for regular object methods
						Utils.runtime_error('Nie można wywolac metody na niezdefiniowanym obiekcie') unless object_value
				
						# evaluate method arguments
						evaluated_args = node.arguments.map { |arg| interpret!(arg, env)[1] }
				
						begin
							result = env.call_method(object_type, node.method_name, object_value, evaluated_args)
							if result.is_a?(Array) && result.size == 2 && result[0].is_a?(Symbol)
								result
							else
								# determine result type
								result_type = case result
															when Integer then :type_int
															when Float then :type_float
															when String then :type_string
															when TrueClass, FalseClass then :type_bool
															when Array then :type_array
															when NilClass then :type_null
															when Hash then :type_object
															else
																Utils.runtime_error("Niespodziewany typ zwrocony z metody #{node.method_name}")
															end
								[result_type, result]
							end
						rescue StandardError => e
							Utils.runtime_error("Blad podczas wykonywania metody #{node.method_name}: #{e.message}")
						end
					end
        elsif node.is_a? AST::MethodCallStmt
          interpret!(node.expression, env)
        elsif node.is_a? AST::ExpressionStmt
          interpret!(node.expression, env)
        elsif node.is_a? AST::ReturnStatement
          raise Utils::ReturnError.new(interpret!(node.value, env))
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
        elsif node.is_a? AST::ImportStmt
          begin
            imported_env = @import_manager.import_file(node.file_path, @current_file, env)
            env.merge(imported_env) # merge imported env with parent env (main file which imports file)
          rescue StandardError => e
            Utils.runtime_error("Blad importu: #{e.message}")
          end
        elsif node.is_a? AST::ThrowStmt
          if node.exception_type
            # Format obiektu z typem i wiadomością
            message_type, message_value = interpret!(node.expression, env)
            
            # check if object is registered
            exception_class = @exception_registry[node.exception_type]
            if exception_class.nil?
              Utils.runtime_error("Nieznany typ wyjątku: #{node.exception_type}", node.line)
            end
            
            # throw respective exception
            raise exception_class.new(message_value, node.line)
          else
            expr_type, expr_value = interpret!(node.expression, env)
            
            if expr_type == :type_string
              # throw base exc 
              raise Utils::WyjatekPodstawowy.new(expr_value, node.line)
            elsif expr_type == :type_object
              # handle case when user passed object directly (not through {} syntax)
              exception_type = expr_value['typ']
              exception_message = expr_value['wiadomosc'] || ""
              
              exception_class = @exception_registry[exception_type] || Utils::WyjatekPodstawowy
              raise exception_class.new(exception_message, node.line)
            else
              Utils.runtime_error("Nieprawidłowy typ dla rzuc: oczekiwano string lub obiekt", node.line)
            end
          end 
        elsif node.is_a? AST::TryCatchStmt
          try_env = env.new_env
          
          begin
            interpret!(node.try_block, try_env)
          rescue StandardError => e
            # check if there is a matching catch block
            caught = false
            
            node.catch_blocks.each do |catch_block|
              # catch_block is AST::CatchBlock instance, so we use its properties
              if catch_block.exception_type
                # check exception type if specified
                type_name = catch_block.exception_type.name
                exception_class = @exception_registry[type_name]
                
                # if exception type doesn't match, move to next catch block
                next unless exception_class && e.is_a?(exception_class)
              end
              
              catch_env = env.new_env
              
              # create new 'e' object inside exception block context
              exception_obj = {}
              exception_obj['wiadomosc'] = {type: :type_string, value: e.message}
              exception_obj['typ'] = {type: :type_string, value: e.class.name.split('::').last}
              exception_obj['linia'] = {type: :type_int, value: (e.respond_to?(:line) ? e.line : nil)}

              catch_env.set_local_var(catch_block.exception_var, exception_obj, :type_object)
              
              # execute catch block
              interpret!(catch_block.body, catch_env)
              caught = true
              break
            end
            
            # if no catch handled the exception, throw it further
            raise e unless caught
          ensure
            # execute finally block if exists
            interpret!(node.finally_block, env.new_env) if node.finally_block
          end
        elsif node.is_a? AST::ExceptionDeclaration
          parent_name = node.parent || 'WyjatekPodstawowy'
          parent_class = @exception_registry[parent_name]
          
          if parent_class.nil?
            Utils.runtime_error("Nieznany typ wyjątku bazowego: #{parent_name}", node.line)
          end
          
          exception_class = Class.new(parent_class)
          @exception_registry[node.name] = exception_class
          
          exception_class.define_singleton_method(:name) { node.name }
          
          [:type_null, 'nic'] 
				elsif node.is_a? AST::ClassDefinition
					# new environment for class
					class_env = env.new_env
					
					# class definition
					class_def = {
						parent: node.parent_class,
						body: node.body,
						methods: {},
						static_methods: {},
						static_vars: {},
						is_abstract: node.is_abstract  # add abstractness flag
					}
					
					# iterate through statements in class body
					in_private_section = false
					in_static_section = false
					
					node.body.stmts.each do |stmt|
						if stmt.is_a?(AST::PrivateSection)
							in_private_section = true
							next
						end
						
						if stmt.is_a?(AST::StaticKeyword)
							in_static_section = true
							next
						end
						
						if stmt.is_a?(AST::FuncDclr)
							if in_static_section
								# static method
								class_def[:static_methods][stmt.name] = {
									declaration: stmt,
									env: class_env,
									private: in_private_section
								}
								in_static_section = false  # reset flag
							else
								# normal instance method
								class_def[:methods][stmt.name] = {
									declaration: stmt,
									env: class_env,
									private: in_private_section
								}
							end
						end
						
						# handle static variables
						if stmt.is_a?(AST::VariableDeclaration) && in_static_section
							value_type, value_value = interpret!(stmt.right, class_env)
							class_def[:static_vars][stmt.left.name] = { type: value_type, value: value_value }
							in_static_section = false  # reset flag
						end
					end
					
					# save class definition in environment
					env.define_class(node.name, class_def)
  
					[:type_null, 'nic'] 

				elsif node.is_a? AST::ClassInstantiation
					# get class definition
					class_def = env.get_class(node.class_name)
					Utils.runtime_error("Nieznana klasa #{node.class_name}", node.line) unless class_def

					# check if class is not abstract
  				Utils.runtime_error("Nie można utworzyć instancji klasy abstrakcyjnej #{node.class_name}", node.line) if class_def[:is_abstract]
					
					# create new instance
					instance = {
						class_name: node.class_name,
						instance_vars: {},  # instance variables
						class_def: class_def  # reference to class definition
					}
					
					# prepare constructor arguments
					arguments = node.arguments.map do |arg|
						interpret!(arg, env)
					end
					
					# call constructor if exists
					# byebug
					constructor = class_def[:instance_methods]["konstruktor"]
					if constructor
						# create environment for constructor
						constructor_env = env.new_env
						constructor_env.set_instance(instance)
						
						# check argument count
						params = constructor[:declaration].params
						
						# handle rest type parameters
						rest_param = params.find(&:rest?)
						min_args = params.count { |p| !p.has_default? && !p.rest? }
						max_args = rest_param ? Float::INFINITY : params.size
						
						if arguments.size < min_args
							Utils.runtime_error(
								"Konstruktor klasy #{node.class_name} oczekiwał minimum #{min_args} argumentów, otrzymał #{arguments.size}",
								node.line
							)
						end
						
						unless rest_param
							if arguments.size > max_args
								Utils.runtime_error(
									"Konstruktor klasy #{node.class_name} oczekiwał maksymalnie #{max_args} argumentów, otrzymał #{arguments.size}",
									node.line
								)
							end
						end
						
						# assign arguments to parameters
						rest_idx = params.index(&:rest?)
						rest_position = rest_idx || params.size
						
						normal_params = params.reject(&:rest?)
						normal_params.each_with_index do |param, idx|
							if idx < arguments.size && (rest_idx.nil? || idx < rest_idx)
								constructor_env.set_local_var(param.name, arguments[idx][1], arguments[idx][0])
							elsif param.has_default?
								default_value = interpret!(param.default_value, constructor[:env])
								constructor_env.set_local_var(param.name, default_value[1], default_value[0])
							else
								Utils.runtime_error("Brakujący argument #{param.name}", node.line)
							end
						end
						
						# handle rest parameter
						if rest_param
							rest_args = arguments[rest_position..-1] || []
							rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
							constructor_env.set_local_var(rest_param.name, rest_array_elements, :type_array)
						end
						
						# execute constructor
						begin
							Utils::ContextTracker.track_method_call("konstruktor") do
								interpret!(constructor[:declaration].body_statement, constructor_env)
							end
						rescue Utils::ReturnError
							# ignore return value from constructor
						end
					end
					
					[:type_instance, instance]
				elsif node.is_a? AST::InstanceVariable
					instance = env.get_instance
					Utils.runtime_error("Nie można użyć zmiennej instancji poza kontekstem instancji", node.line) unless instance
					
					# get instance variable value
					value = instance[:instance_vars][node.name]
					if value.nil?
						[:type_null, 'nic']  # uninitialized instance variable returns 'nic'
					else
						value
					end				
				elsif node.is_a? AST::InstanceVariableAssignment
					instance = env.get_instance
					Utils.runtime_error("Nie można przypisać zmiennej instancji poza kontekstem instancji", node.line) unless instance
					
					# evaluate value to assign
					value_type, value_value = interpret!(node.value, env)
					
					# assign value to instance variable
					instance[:instance_vars][node.name] = [value_type, value_value]
					
					[value_type, value_value]
        elsif node.is_a? AST::InstanceMethodCall
          # evaluate object
          obj_type, obj_value = interpret!(node.object, env)
          Utils.runtime_error("Próba wywołania metody na obiekcie, który nie jest instancją", node.line) unless obj_type == :type_instance
          
          # get class definition
          class_def = obj_value[:class_def]
          
          # get method
          method_def = class_def[:methods][node.method_name]
          Utils.runtime_error("Nieznana metoda #{node.method_name}", node.line) unless method_def
          
          # check if method is private
          if method_def[:private]
            # check if we're in context of same instance
            current_instance = env.get_instance
            unless current_instance && current_instance.equal?(obj_value)
              Utils.runtime_error("Próba wywołania prywatnej metody #{node.method_name}", node.line)
            end
          end
          
          # evaluate arguments
          arg_values = node.arguments.map { |arg| interpret!(arg, env) }
          
          # create environment for method
          method_env = method_def[:env].new_env
          method_env.set_instance(obj_value)  # set current instance
          
          # assign arguments to parameters
          method_def[:declaration].params.zip(arg_values).each do |param, arg|
            method_env.set_var(param.name, arg[1], arg[0])
          end
          
          # execute method body
					begin
						Utils::ContextTracker.track_method_call(node.method_name) do
							interpret!(method_def[:declaration].body, method_env)
						end
						[:type_null, 'nic']  # default return value
					rescue Utils::ReturnError => e
						e.value
					end
				elsif node.is_a? AST::InstanceVariableDeclaration
					instance = env.get_instance
					Utils.runtime_error("Nie można zadeklarować zmiennej instancji poza kontekstem instancji", node.line) unless instance
					
					# evaluate value
					value_type, value_value = interpret!(node.value, env)
					
					# save instance variable
					instance[:instance_vars][node.name] = [value_type, value_value]
					
					[value_type, value_value]
				elsif node.is_a? AST::SuperMethodCall
					# check if we're in instance context
					instance = env.get_instance
					Utils.runtime_error("Nie można użyć 'super' poza kontekstem instancji", node.line) unless instance
					
					# determine method name
					current_method_name = node.method_name || Utils::ContextTracker.current_method_name
					
					if current_method_name.nil?
						if instance[:instance_vars].size <= 1
							current_method_name = "konstruktor"
						else
							Utils.runtime_error("Nie można określić kontekstu metody dla wywołania 'super()'", node.line)
						end
					end
					
					# find method in parent class using optimized lookup
					method_result = env.find_parent_method(instance, current_method_name)
					Utils.runtime_error("Nie znaleziono metody #{current_method_name} w klasie nadrzędnej", node.line) unless method_result
					
					method_info = method_result[:method_info]
					
					# evaluate arguments
					arguments = node.arguments.map { |arg| interpret!(arg, env) }
					
					# check argument count using preserved parameter information
					param_names = method_info[:param_names]
					param_defaults = method_info[:param_defaults]
					param_rest_flags = method_info[:param_rest_flags]
					
					has_rest = method_info[:has_rest]
					min_args = param_defaults.count(&:nil?)
					max_args = has_rest ? Float::INFINITY : param_names.size
					
					if arguments.size < min_args
						Utils.runtime_error(
							"Metoda #{current_method_name} oczekiwała minimum #{min_args} argumentów, otrzymała #{arguments.size}",
							node.line
						)
					end
					
					unless has_rest
						if arguments.size > max_args
							Utils.runtime_error(
								"Metoda #{current_method_name} oczekiwała maksymalnie #{max_args} argumentów, otrzymała #{arguments.size}",
								node.line
							)
						end
					end
					
					# create new environment for method
					method_env = method_info[:env].new_env
					method_env.set_instance(instance)
					
					# assign arguments to parameters using preserved names
					param_names.each_with_index do |param_name, idx|
						if idx < arguments.size && !param_rest_flags[idx]
							method_env.set_local_var(param_name, arguments[idx][1], arguments[idx][0])
						elsif param_defaults[idx] && !param_rest_flags[idx]
							default_value = interpret!(param_defaults[idx], env)
							method_env.set_local_var(param_name, default_value[1], default_value[0])
						elsif param_rest_flags[idx]
							rest_args = arguments[idx..-1] || []
							rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
							method_env.set_local_var(param_name, rest_array_elements, :type_array)
							break
						elsif param_defaults[idx].nil?
							Utils.runtime_error("Brakujący argument #{param_name}", node.line)
						end
					end
					
					# execute method body
					begin
						Utils::ContextTracker.track_method_call(current_method_name) do
							interpret!(method_info[:declaration].body_statement, method_env)
						end
						result = [:type_null, 'nic']
					rescue Utils::ReturnError => e
						result = e.value
					end
					
					result
				elsif node.is_a? AST::StaticVariable
					# get class definition
					class_def = env.get_class(node.class_name)
					Utils.runtime_error("Nieznana klasa #{node.class_name}", node.line) unless class_def
					
					# look for static variable in whole class hierarchy
					var = nil
					current_class_def = class_def
					
					while current_class_def && !var
						# check if variable exists in current class
						if current_class_def[:static_vars] && current_class_def[:static_vars][node.name]
							var = current_class_def[:static_vars][node.name]
							break
						end
						
						# if not, check base class
						parent_name = current_class_def[:parent]
						break unless parent_name
						
						current_class_def = env.get_class(parent_name)
					end
					
					Utils.runtime_error("Nieznana zmienna statyczna '#{node.name}' w klasie #{node.class_name}", node.line) unless var
					
					[var[:type], var[:value]]
				elsif node.is_a? AST::StaticVariableDeclaration
					class_name = node.class_name
					class_def = env.get_class(class_name)
					
					# check if class exists
					if class_def.nil?
						Utils.runtime_error("Nie można zdefiniować zmiennej statycznej dla nieistniejącej klasy #{class_name}", node.line)
					end
					
					# check if we're not trying to overwrite existing static variable
					if class_def[:static_vars][node.name] && node.name.match?(/^[A-Z_]+$/)
						Utils.runtime_error("Statyczna stała #{class_name}.#{node.name} została już zdefiniowana i nie może być zmieniona", node.line)
					end

					value_type, value_value = interpret!(node.value, env)
					env.set_static_var(node.class_name, node.name, value_value, value_type)
					
					[value_type, value_value]
				elsif node.is_a? AST::StaticMethodCall
					# get class definition
					class_def = env.get_class(node.class_name)
					Utils.runtime_error("Nieznana klasa #{node.class_name}", node.line) unless class_def
					
					# get static method using new optimized lookup
					method_info = env.get_static_method(node.class_name, node.method_name)
					Utils.runtime_error("Nieznana metoda statyczna '#{node.method_name}' w klasie #{node.class_name}", node.line) unless method_info
					
					# evaluate arguments
					arguments = node.arguments.map do |arg|
						interpret!(arg, env)
					end
					
					# check argument count using preserved parameter information
					param_names = method_info[:param_names]
					param_defaults = method_info[:param_defaults]
					param_rest_flags = method_info[:param_rest_flags]
					
					has_rest = method_info[:has_rest]
					min_args = param_defaults.count(&:nil?) # params without defaults
					max_args = has_rest ? Float::INFINITY : param_names.size
					
					if arguments.size < min_args
						Utils.runtime_error(
							"Metoda statyczna '#{node.method_name}' oczekiwała minimum #{min_args} argumentów, otrzymała #{arguments.size}",
							node.line
						)
					end
					
					unless has_rest
						if arguments.size > max_args
							Utils.runtime_error(
								"Metoda statyczna '#{node.method_name}' oczekiwała maksymalnie #{max_args} argumentów, otrzymała #{arguments.size}",
								node.line
							)
						end
					end
					
					# create new environment for static method
					method_env = env.new_env
					
					# assign arguments to parameters using preserved names
					param_names.each_with_index do |param_name, idx|
						if idx < arguments.size && !param_rest_flags[idx]
							# regular parameter with provided argument
							method_env.set_local_var(param_name, arguments[idx][1], arguments[idx][0])
						elsif param_defaults[idx] && !param_rest_flags[idx]
							# parameter with default value
							default_value = interpret!(param_defaults[idx], env)
							method_env.set_local_var(param_name, default_value[1], default_value[0])
						elsif param_rest_flags[idx]
							# rest parameter - collect remaining arguments
							rest_args = arguments[idx..-1] || []
							rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
							method_env.set_local_var(param_name, rest_array_elements, :type_array)
							break # rest parameter is always last
						elsif param_defaults[idx].nil?
							Utils.runtime_error("Brakujący argument '#{param_name}'", node.line)
						end
					end
					
					# execute static method body using preserved declaration
					begin
						Utils::ContextTracker.track_method_call(node.method_name) do
							interpret!(method_info[:declaration].body_statement, method_env)
						end
						result = [:type_null, 'nic']
					rescue Utils::ReturnError => e
						result = e.value
					end
					
					result

				elsif node.is_a? AST::RubyCall
					module_path = node.module_path
					method_name = node.method_name
					
					# evaluate arguments
					args = node.arguments.map do |arg|
						type, value = interpret!(arg, env)
						{ type: type, value: value }
					end
					
					# execute safe ruby call
					# p "module: #{module_path}, method_name: #{method_name}, args: #{args}, file: #{@current_file}"
					result = Utils::RubyEvaluator.safe_call(module_path, method_name, args, @current_file)
					[result[:type], result[:value]]
				elsif node.is_a? AST::RubyCallStmt
					interpret!(node.expression, env)
				elsif node.is_a? AST::RequireRubyStmt
					begin
						success = Utils::RubyEvaluator.require_library(node.library_name, @current_file)
						[:type_bool, success ? 'prawda' : 'falsz']
					rescue StandardError => e
						Utils.runtime_error("Błąd podczas importu biblioteki Ruby: #{e.message}", node.line)
					end
				elsif node.is_a? AST::RubyObjCall
					object_type, object_value = interpret!(node.object, env)
					
					# check if object is ruby_object type
					if object_type != :type_ruby_object
						Utils.runtime_error("Operacja ruby_obj wymaga obiektu Ruby, otrzymano: #{object_type}", node.line)
					end
					
					# get ruby object id
					object_id = object_value[:id]
					
					# evaluate arguments
					args = node.arguments.map do |arg|
						type, value = interpret!(arg, env)
						{ type: type, value: value }
					end
					
					# call method on ruby object
					result = Utils::RubyEvaluator.call_object_method(object_id, node.method_name, args, @current_file)
					
					[result[:type], result[:value]]
				
				elsif node.is_a? AST::RubyObjCallStmt
					interpret!(node.expression, env)
        end
      end

      # entry point of interpreter creating brand new global/parent environment
      def interpret_ast(node, env = nil)
        begin
          environment = env || Environment.new
          interpret!(node, environment)
        rescue StandardError => e
          raise e if e.is_a?(Utils::WyjatekPodstawowy)
          
          # translate native ruby exception to AS one
          raise Utils::ExceptionsTranslator.translate(e)
        end
      end

      private

      def runtime_error(left_value, right_value, node)
        Utils.runtime_error("Niewspierany operator #{node.op.lexeme} pomiedzy #{left_value} a #{right_value}",
                            node.op.line)
      end

      def runtime_error_unop(value, node)
        Utils.runtime_error("Niewspierany operator #{node.op.lexeme} z #{value}", node.op.line)
      end

      def validate_function_value(val)
        return false unless val && val[:type] == :type_function
        return false unless val[:value] && val[:value][:declaration] && val[:value][:env]

        true
      end

      def is_truthy?(type, value, line)
        case type
        when :type_bool
          value == BOOL_TRUE
        when :type_null
          false
        else
          Utils.runtime_error('Warunek musi byc boolem lub "nic"', line)
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
          "#{key}: #{formatted}"
        end
        "{#{pairs.join(', ')}}"
      end
    end
  end
end
