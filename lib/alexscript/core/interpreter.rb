# frozen_string_literal: true

require 'weakref'

module AlexScript
  module Core
    class Interpreter
			include Helpers::DeepEquality, Helpers::ValueFormatter, Helpers::TypeConverter, Helpers::ValidationHelper, Helpers::ExceptionHandler

      def initialize
        @import_manager = Utils::ImportManager.new
        @current_file = 'main'
      end

      def set_current_file(file)
        @current_file = file
        Utils::ContextTracker.current_file = file
      end

      def interpret!(node, env)
        Utils::ContextTracker.current_line = node.line if node.respond_to?(:line) # always set line first

				# Debugger stepping hook
    		Utils::Debugger.check(node, env, self) if Utils::Debugger.stepping?

        if node.is_a? AST::Int
          [:type_int, node.value.to_i]
        elsif node.is_a? AST::Flt
          [:type_float, node.value.to_f]
        elsif node.is_a? AST::Str
          [:type_string, node.value.to_s]
        elsif node.is_a? AST::Bool
          # Return PrimivieValue instead of string
          bool_value = node.value == 'prawda' ? Utils::BOOL_TRUE : Utils::BOOL_FALSE
          [:type_bool, bool_value]
        elsif node.is_a? AST::Null
          [:type_null, Utils::NULL_VALUE]
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
              return [:type_null, Utils::NULL_VALUE] # all logical operations with null returns null
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
                %i[type_int type_string], %i[type_float type_string],
                %i[type_string type_bool], %i[type_bool type_string]
              # conversion of bool to string
              left_str = left_type == :type_bool ? (from_bool_value(left_value) ? "prawda" : "falsz") : left_value.to_s
              right_str = right_type == :type_bool ? (from_bool_value(right_value) ? "prawda" : "falsz") : right_value.to_s
              [:type_string, left_str + right_str]
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
							# Only update variable in env if left side is an identifier (a variable)
							if node.left.is_a?(AST::Identifier)
								env.set_var(node.left.name, left_value, left_type)
							end
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
						[:type_bool, to_bool_value(deep_equal?(left_type, left_value, right_type, right_value))]
          elsif node.op.token_type == :tok_noteq # !=
						[:type_bool, to_bool_value(!deep_equal?(left_type, left_value, right_type, right_value))]
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
              [:type_bool, Utils::BOOL_TRUE] # !nic returns true
            else
              runtime_error_unop(operand_value, node)
            end
          end

        # short-circut evaluation for logical operators, left 'and' is false => false, left 'or' is true => true
        # otherwise search for the right side
        elsif node.is_a? AST::LogicalOp
          left_type, left_value = interpret!(node.left, env)

          if node.op.token_type == :tok_or
            return [left_type, left_value] if left_value == Utils::BOOL_TRUE
          elsif node.op.token_type == :tok_and
            return [left_type, left_value] if left_value == Utils::BOOL_FALSE || left_type == :type_null
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
          formatted_value = format_value(expression_type, expression_value)
          
          # For special values (bool, null), use puts to avoid adding quotes
          # For other types, use p() which preserves string quotes
          if expression_type == :type_bool || expression_type == :type_null
            puts formatted_value
          else
            p(formatted_value)
          end

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
            break unless test_value == Utils::BOOL_TRUE

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
            while to_bool_value(index_value < end_value) == Utils::BOOL_TRUE
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
            while to_bool_value(index_value > end_value) == Utils::BOOL_TRUE
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
          env.set_func(node.name, [node, WeakRef.new(env)])# TODO: improve memory management here
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
								if current_instance[:module_path] && !current_instance[:module_path].empty?
									current_class_def = env.get_module_class(current_instance[:module_path], current_class_name)
								else
									current_class_def = env.get_class(current_class_name)
								end
								
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
								Utils::CallStackTracker.push(:function, node.name, @current_file, node.line) # for exception handler
								begin
									Utils::ContextTracker.track_method_call(node.name) do
										interpret!(func_declr.body_statement, new_func_env)
									end
									result = [:type_null, Utils::NULL_VALUE] # return 'nic' if function does not return any value
								rescue Utils::ReturnError => e
									result = e.value
								ensure
    							Utils::CallStackTracker.pop
								end
							end
						end
						
						# end of new code - proceed to standard function handling
						# if no class method was found
						unless class_method_called
							var = env.get_var(node.name)
					
							Utils.runtime_error("Niepoprawna wartosc funkcji dla #{node.name}", node.line) if var && !validate_function_value(var)
					
							if var && var[:type] == :type_function
								# if it's a variable containing function
								func_declr = var[:value][:declaration]
								func_env = var[:value][:env]
							else
								# if not, just check for a regular function
								func = env.get_func(node.name)
								Utils.runtime_error("Funkcja #{node.name} nie zostala zadeklarowana w obecnym zakresie", node.line) unless func
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
							Utils::CallStackTracker.push(:function, node.name, @current_file, node.line) # for exception handler
							begin
								Utils::ContextTracker.track_method_call(node.name) do
									interpret!(func_declr.body_statement, new_func_env)
								end
								result = [:type_null, Utils::NULL_VALUE] # return 'nic' if function does not return any value
							rescue Utils::ReturnError => e
								result = e.value
							ensure
    						Utils::CallStackTracker.pop
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
						if value
							[value[:type], value[:value]]
						else
							[:type_null, Utils::NULL_VALUE]
						end
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
							class_def[:name] ||= node.class_name

							# add environment access for methods that need it
							evaluated_args.unshift(env) if [:przodkowie, :czy_dziedziczy_po].include?(node.method_name.to_sym)

							# try to call built-in class method
							result = env.call_method(:type_class, node.method_name, class_def, evaluated_args)
							
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
						
						# Native static method dispatch
            if class_def[:native]
              native_static = class_def[:native_static_methods]
              if native_static && native_static.key?(node.method_name)
                arguments = node.arguments.map { |arg| interpret!(arg, env) }

                begin
                  result = Utils::NativeClassRegistry.dispatch_static_method(
                    class_name, node.method_name, arguments
                  )
                rescue => e
                  Utils.runtime_error(
                    "Błąd metody statycznej #{node.method_name} klasy #{class_name}: #{e.message}",
                    node.line
                  )
                end

                return result
              end

              # If not found as native static, fall through to error
              Utils.runtime_error(
                "Nieznana metoda statyczna '#{node.method_name}' w klasie #{class_name}",
                node.line
              )
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
									"Metoda statyczna #{node.method_name} oczekiwała, a minimum #{min_args} argumentów, otrzymała #{arguments.size}",
									node.line
								)
							end
							
							unless rest_param
								if arguments.size > max_args
									Utils.runtime_error(
										"Metoda statyczna #{node.method_name} oczekiwała, a maksymalnie #{max_args} argumentów, otrzymała #{arguments.size}",
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
							Utils::ContextTracker.current_class_name = object_value[:class_name]
							Utils::CallStackTracker.push(:method,node.method_name,@current_file,node.line) 
							begin	
								Utils::ContextTracker.track_method_call(node.method_name) do
									interpret!(method_info[:declaration].body_statement, method_env)
								end
								result = [:type_null, Utils::NULL_VALUE]  # by default return 'nic'
							rescue Utils::ReturnError => e
								result = e.value  # or specific value returned by method
							ensure
    						Utils::CallStackTracker.pop
							end
							
							return result
						else
							Utils.runtime_error("Nieznana metoda statyczna '#{node.method_name}' w klasie #{class_name}", node.line)
						end
					end
				
					# handle class instance methods
					if object_type == :type_instance
						# first check if this is a built-in info method for instance
						if env.built_in_methods.get_method(:type_instance, node.method_name)
							evaluated_args = node.arguments.map { |arg| interpret!(arg, env)[1] }
							
							result = env.call_method(:type_instance, node.method_name, object_value, evaluated_args)
							
							# Sprawdz czy juz zwrocone jako tuple
							if result.is_a?(Array) && result.size == 2 && result[0].is_a?(Symbol)
							return result
							end
							
							# conver Ruby vals to AlexScript
							result_type = case result
										when Integer then :type_int
										when Float then :type_float
										when String then :type_string
										when TrueClass, FalseClass then :type_bool
										when Array then :type_array
										when NilClass then :type_null
										when Hash then :type_object
										else :type_object
										end
							
							return [result_type, result]
						end


						# Native instance method dispatch
            if object_value[:class_def] && object_value[:class_def][:native]
              native_methods = object_value[:class_def][:native_methods]
              if native_methods && native_methods.key?(node.method_name)
                arguments = node.arguments.map { |arg| interpret!(arg, env) }

                begin
                  result = Utils::NativeClassRegistry.dispatch_instance_method(
                    object_value, node.method_name, arguments
                  )
                rescue => e
                  Utils.runtime_error(
                    "Błąd metody #{node.method_name} klasy #{object_value[:class_name]}: #{e.message}",
                    node.line)
                end

                return result
              end
            end
						
						# find method in class hierarchy
						method_result = env.find_method_in_hierarchy(object_value, node.method_name)
						Utils.runtime_error("Nieznana metoda #{node.method_name} dla instancji klasy #{object_value[:class_name]}", node.line) unless method_result
						
						method_info = method_result[:method_info]
						
						# check if method is private
						if method_info[:private]
							current_instance = env.get_instance
							# private method can be called:
							# 1. from same instance
							# 2. from methods of same class (or subclass if inherited)
							
							same_instance = current_instance == object_value
							from_inside_class = current_instance && current_instance[:class_name] == object_value[:class_name]
							from_subclass = current_instance && env.is_subclass_of(current_instance[:class_name], object_value[:class_name])
							
							unless same_instance || from_inside_class || from_subclass
								Utils.runtime_error("Próba wywołania prywatnej metody #{node.method_name}", node.line)
							end
						end
											
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
								"Metoda #{node.method_name} oczekiwała, a minimum #{min_args} argumentów, otrzymała #{arguments.size}",
								node.line
							)
						end
						
						unless rest_param
							if arguments.size > max_args
								Utils.runtime_error(
									"Metoda #{node.method_name} oczekiwała, a maksymalnie #{max_args} argumentów, otrzymała #{arguments.size}",
									node.line
								)
							end
						end
						
						# create new environment for method
						method_env = method_info[:env].new_env
						method_env.set_instance(object_value)
						
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
						
						# execute method body
						Utils::ContextTracker.current_class_name = object_value[:class_name]
						Utils::CallStackTracker.push(:method,node.method_name,@current_file,node.line)
						begin
							Utils::ContextTracker.track_method_call(node.method_name) do
								interpret!(method_info[:declaration].body_statement, method_env)
							end
							result = [:type_null, Utils::NULL_VALUE]  # by default return 'nic'
						rescue Utils::ReturnError => e
							result = e.value  # or specific value returned by method
						ensure
							Utils::CallStackTracker.pop
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
							Utils.runtime_error("Blad podczas wykonywania metody #{node.method_name}: #{e.message}", node.line)
						end
					end
        elsif node.is_a? AST::MethodCallStmt
          interpret!(node.expression, env)
        elsif node.is_a? AST::ExpressionStmt
          interpret!(node.expression, env)
        elsif node.is_a? AST::ReturnStatement
          raise Utils::ReturnError.new(interpret!(node.value, env))
				elsif node.is_a? AST::DebugBreak
    			Utils::Debugger.activate!(node, env, self)
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
					handle_throw_statement(node, env)
        elsif node.is_a? AST::TryCatchStmt
					handle_try_catch_statement(node, env)
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
						is_abstract: node.is_abstract,
						included_modules: []
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

						# handle include module (dolacz)
						if stmt.is_a?(AST::IncludeModule)
							module_def = env.get_module(stmt.module_name)
							
							unless module_def
								Utils.runtime_error("Nie znaleziono modułu #{stmt.module_name}", stmt.line)
							end

							# fetch constants from module
							if module_def[:constants]
								module_def[:constants].each do |const_name, const_data|
									class_env.set_local_var(const_name, const_data[:value], const_data[:type], true)
								end
							end

							# add module functions as a class methods 
							if module_def[:functions]
								module_def[:functions].each do |func_name, func_data|
									func_declr, _module_env = func_data
									
									# skip if method already exist
									next if class_def[:methods].key?(func_name)
									
									class_def[:methods][func_name] = {
										declaration: func_declr,
										env: class_env, 
										private: false
									}
								end
							end
							
							class_def[:included_modules] << stmt.module_name
							next
						end
						
						if stmt.is_a?(AST::FuncDclr)
							if in_static_section
								# static method
								class_def[:static_methods][stmt.name] = {
									declaration: stmt,
									env: WeakRef.new(class_env),
									private: in_private_section
								}
								in_static_section = false  # reset flag
							else
								# normal instance method
								class_def[:methods][stmt.name] = {
									declaration: stmt,
									env: WeakRef.new(class_env),
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

					class_def[:class_env] = class_env
					
					# save class definition in environment
					env.define_class(node.name, class_def)
  
					[:type_null, Utils::NULL_VALUE] 

				elsif node.is_a? AST::ClassInstantiation
					# get class definition
					class_def = env.get_class(node.class_name)
					Utils.runtime_error("Nieznana klasa #{node.class_name}", node.line) unless class_def

					# check if class is not abstract
  				Utils.runtime_error("Nie można utworzyć instancji klasy abstrakcyjnej #{node.class_name}", node.line) if class_def[:is_abstract]

					# Native class constructor 
          if class_def[:native]
            arguments = node.arguments.map { |arg| interpret!(arg, env) }

            begin
              native_obj = Utils::NativeClassRegistry.dispatch_constructor(node.class_name, arguments)
            rescue => e
              Utils.runtime_error("Błąd konstruktora natywnego #{node.class_name}: #{e.message}", node.line)
            end

            instance = {
              class_name: node.class_name,
              instance_vars: {},
              class_def: class_def,
              __native__: native_obj
            }

            return [:type_instance, instance]
          end
					
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
					constructor = class_def[:methods]["konstruktor"]
					if constructor
						# create environment for constructor
						constructor_env = constructor[:env].new_env
						constructor_env.set_instance(instance)
						
						# check argument count
						params = constructor[:declaration].params
						
						# handle rest type parameters
						rest_param = params.find(&:rest?)
						min_args = params.count { |p| !p.has_default? && !p.rest? }
						max_args = rest_param ? Float::INFINITY : params.size
						
						if arguments.size < min_args
							Utils.runtime_error(
								"Konstruktor klasy #{node.class_name} oczekiwał minimum #{min_args} argumentów, otrzymała #{arguments.size}",
								node.line
							)
						end
						
						unless rest_param
							if arguments.size > max_args
								Utils.runtime_error(
									"Konstruktor klasy #{node.class_name} oczekiwała maksymalnie #{max_args} argumentów, otrzymała #{arguments.size}",
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
						Utils::ContextTracker.current_class_name = node.class_name
						Utils::CallStackTracker.push(:constructor, node.class_name, @current_file, node.line)
						begin
							Utils::ContextTracker.track_method_call("konstruktor") do
								interpret!(constructor[:declaration].body_statement, constructor_env)
							end
						rescue Utils::ReturnError
							# ignore return value from constructor
						ensure
  						Utils::CallStackTracker.pop
						end
					end
					
					[:type_instance, instance]
				elsif node.is_a? AST::ModuleDefinition
					module_def = {
						name: node.name,
						classes: {},
						functions: {},
						constants: {},
						nested_modules: {},
						parent_module: node.parent_module,
						body: node.body
					}
					
					# create env for module contents
					module_env = env.new_env
					module_def[:module_env] = module_env
					
					# process constants and functions
					node.body.stmts.each do |stmt|
						if stmt.is_a?(AST::VariableDeclaration)
							var_name = stmt.left.name
							if var_name.match?(/^[A-Z_]+$/)
								value_type, value_value = interpret!(stmt.right, module_env)
								module_def[:constants][var_name] = { type: value_type, value: value_value }
								# save constants in module_env for classes 
								module_env.set_local_var(var_name, value_value, value_type, true)
							else
								Utils.runtime_error("Tylko stałe (WIELKIE_LITERY) mogą być definiowane w module", stmt.line)
							end
						elsif stmt.is_a?(AST::FuncDclr)
							# function in module
							module_def[:functions][stmt.name] = [stmt, module_env]
							# save function in module_env
							module_env.set_func(stmt.name, [stmt, WeakRef.new(module_env)])
						end
					end
					
					# process classes that already have access to constants and/or functions
					node.body.stmts.each do |stmt|
						if stmt.is_a?(AST::ClassDefinition)
							# class inside module
							class_def = {
								parent: stmt.parent_class,
								body: stmt.body,
								methods: {},
								static_methods: {},
								static_vars: {},
								is_abstract: stmt.is_abstract
							}
							
							# process class body
							in_private = false
							in_static = false
							
							stmt.body.stmts.each do |class_stmt|
								if class_stmt.is_a?(AST::PrivateSection)
									in_private = true
								elsif class_stmt.is_a?(AST::StaticKeyword)
									in_static = true
								elsif class_stmt.is_a?(AST::IncludeModule)		
									included_module_name = class_stmt.module_name
									included_module_def = nil
									
									# first, search in nested_modules of the same parent module (sibling)
									if module_def[:nested_modules] && module_def[:nested_modules][included_module_name]
										included_module_def = module_def[:nested_modules][included_module_name]
									else
										# if not found locally, search globally
										included_module_def = env.get_module(included_module_name)
									end
									
									unless included_module_def
										Utils.runtime_error("Nie znaleziono modułu #{included_module_name}", class_stmt.line)
									end
									
								
									# copy functions from module as instance methods
									if included_module_def[:functions]
										included_module_def[:functions].each do |func_name, func_data|
											# don't overwrite if class already has this method
											if class_def[:methods].key?(func_name)
												next
											end
											
											class_def[:methods][func_name] = {
												declaration: func_data[0],
												env: func_data[1],  # use env from module
												private: in_private
											}
										end
									end
									
									# copy constants from module to module_env
									if included_module_def[:constants]
										included_module_def[:constants].each do |const_name, const_data|
											module_env.set_local_var(const_name, const_data[:value], const_data[:type], true)
										end
									end
																		
								elsif class_stmt.is_a?(AST::FuncDclr)
									if in_static
										class_def[:static_methods][class_stmt.name] = {
											declaration: class_stmt,
											env: module_env,
											private: in_private
										}
										in_static = false
									else
										class_def[:methods][class_stmt.name] = {
											declaration: class_stmt,
											env: module_env,
											private: in_private
										}
									end
								elsif class_stmt.is_a?(AST::VariableDeclaration) && in_static
									value_type, value_value = interpret!(class_stmt.right, module_env)
									class_def[:static_vars][class_stmt.left.name] = { type: value_type, value: value_value }
									in_static = false
								end
							end
							
							module_def[:classes][stmt.name] = class_def
							
						elsif stmt.is_a?(AST::ModuleDefinition)
							# nested module - recurse
							nested_module_def = interpret!(stmt, module_env)
							module_def[:nested_modules][stmt.name] = nested_module_def
						end
					end

					module_def.delete(:body) # delete AST body after processiong
					
					# register ONLY top-level modules
					if node.parent_module.nil?
						env.define_module(node.name, module_def)
					end
					
					module_def
				elsif node.is_a? AST::ModuleAccess
					# Modul::funkcja() or Modul::STALA
					module_path = node.module_path
					member_name = node.member_name
					
					# try function first
					func = env.get_module_function(module_path, member_name)
					if func
						return [:type_function, { declaration: func[0], env: func[1] }]
					end
					
					# try constant
					constant = env.get_module_constant(module_path, member_name)
					if constant
						return [constant[:type], constant[:value]]
					end
					
					# try class (for static access)
					class_def = env.get_module_class(module_path, member_name)
					if class_def
						return [:type_class, class_def]
					end
					
					path_str = module_path.join("::")
					Utils.runtime_error("Nie znaleziono '#{member_name}' w module #{path_str}", node.line)

				elsif node.is_a? AST::ModuleClassInstantiation
					# Modul::Klasa.nowy(args)
					module_path = node.module_path
					class_name = node.class_name
					
					class_def = env.get_module_class(module_path, class_name)
					
					unless class_def
						path_str = module_path.join("::")
						Utils.runtime_error("Nie znaleziono klasy #{class_name} w module #{path_str}", node.line)
					end
					
					if class_def[:is_abstract]
						Utils.runtime_error("Nie można utworzyć instancji klasy abstrakcyjnej #{class_name}", node.line)
					end

					# native class constructor (in module)
          if class_def[:native]
            arguments = node.arguments.map { |arg| interpret!(arg, env) }

            begin
              native_obj = Utils::NativeClassRegistry.dispatch_constructor(class_name, arguments)
            rescue => e
              Utils.runtime_error("Błąd konstruktora natywnego #{class_name}: #{e.message}", node.line)
            end

            instance = {
              class_name: class_name,
              module_path: module_path,
              instance_vars: {},
              class_def: class_def,
              __native__: native_obj
            }
            return [:type_instance, instance]
          end
					
					# create instance like normal
					instance = {
						class_name: class_name,
						module_path: module_path,  # track module origin
						instance_vars: {},
						class_def: class_def
					}
					
					# call constructor
					constructor = class_def[:methods]["konstruktor"]
					if constructor
						arguments = node.arguments.map { |arg| interpret!(arg, env) }
						
						constructor_env = constructor[:env].new_env
						constructor_env.set_instance(instance)
						
						params = constructor[:declaration].params
						rest_param = params.find(&:rest?)
						min_args = params.count { |p| !p.has_default? && !p.rest? }
						max_args = rest_param ? Float::INFINITY : params.size
						
						if arguments.size < min_args
							Utils.runtime_error("Konstruktor oczekiwał minimum #{min_args} argumentów, otrzymał #{arguments.size}", node.line)
						end
						
						unless rest_param
							if arguments.size > max_args
								Utils.runtime_error("Konstruktor oczekiwał maksymalnie #{max_args} argumentów, otrzymał #{arguments.size}", node.line)
							end
						end
						
						# assign params
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
						
						if rest_param
							rest_args = arguments[rest_position..-1] || []
							rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
							constructor_env.set_local_var(rest_param.name, rest_array_elements, :type_array)
						end
						
						# execute constructor
						Utils::ContextTracker.current_class_name = class_name
						Utils::CallStackTracker.push(:constructor, class_name, @current_file, node.line)
						begin
							Utils::ContextTracker.track_method_call("konstruktor") do
								interpret!(constructor[:declaration].body_statement, constructor_env)
							end
						rescue Utils::ReturnError
							# ignore
						ensure
							Utils::CallStackTracker.pop
						end
					end
					
					[:type_instance, instance]
				elsif node.is_a? AST::ModuleFunctionCall
					# Modul::funkcja(args)
					module_path = node.module_path
					function_name = node.function_name
					
					func = env.get_module_function(module_path, function_name)
					
					unless func
						path_str = module_path.join("::")
						Utils.runtime_error("Nie znaleziono funkcji '#{function_name}' w module #{path_str}", node.line)
					end
					
					# func to [declaration, env]
					func_declr = func[0]
					func_env = func[1]
					
					# evaluate arguments
					arguments = node.arguments.map { |arg| interpret!(arg, env) }
					
					# validate argument count
					params = func_declr.params
					rest_param = params.find(&:rest?)
					min_args = params.count { |p| !p.has_default? && !p.rest? }
					max_args = rest_param ? Float::INFINITY : params.size
					
					if arguments.size < min_args
						Utils.runtime_error(
							"Funkcja #{function_name} oczekiwała minimum #{min_args} argumentów, otrzymała #{arguments.size}",
							node.line
						)
					end
					
					unless rest_param
						if arguments.size > max_args
							Utils.runtime_error(
								"Funkcja #{function_name} oczekiwała maksymalnie #{max_args} argumentów, otrzymała #{arguments.size}",
								node.line
							)
						end
					end
					
					# create new env for function
					new_func_env = func_env.new_env
					
					# assign parameters
					rest_idx = params.index(&:rest?)
					rest_position = rest_idx || params.size
					normal_params = params.reject(&:rest?)
					
					normal_params.each_with_index do |param, idx|
						if idx < arguments.size && (rest_idx.nil? || idx < rest_idx)
							new_func_env.set_local_var(param.name, arguments[idx][1], arguments[idx][0])
						elsif param.has_default?
							default_value = interpret!(param.default_value, func_env)
							new_func_env.set_local_var(param.name, default_value[1], default_value[0])
						else
							Utils.runtime_error("Brakujący argument #{param.name}", node.line)
						end
					end
					
					if rest_param
						rest_args = arguments[rest_position..-1] || []
						rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
						new_func_env.set_local_var(rest_param.name, rest_array_elements, :type_array)
					end
					
					# execute function
					env.increment_call_depth(node.line)
					Utils::CallStackTracker.push(:function, function_name, @current_file, node.line)
					begin
						Utils::ContextTracker.track_method_call(function_name) do
							interpret!(func_declr.body_statement, new_func_env)
						end
						result = [:type_null, Utils::NULL_VALUE]
					rescue Utils::ReturnError => e
						result = e.value
					ensure
						Utils::CallStackTracker.pop
						env.decrement_call_depth
					end
					
					result
				elsif node.is_a? AST::InstanceVariable
						instance = env.get_instance
						Utils.runtime_error("Nie można użyć zmiennej instancji poza kontekstem instancji", node.line) unless instance
						
						# get instance variable value
						value = instance[:instance_vars][node.name]
						if value.nil?
							[:type_null, Utils::NULL_VALUE]  # uninitialized instance variable returns 'nic'
						else
							value
						end
					elsif node.is_a? AST::SelfReference
						instance = env.get_instance
						
						unless instance
							Utils.runtime_error(
								"Nie można użyć 'sam' poza kontekstem instancji klasy. 'sam' może być użyte tylko w metodach instancji i konstruktorze.",
								node.line
							)
						end
						
						[:type_instance, instance]
				elsif node.is_a? AST::InstanceVariableAssignment		
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
						[:type_null, Utils::NULL_VALUE]  # default return value
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
					current_method_name = nil
					
					if node.method_name.nil?
						# 1. most important change: always try to read current method context
						current_method_name = Utils::ContextTracker.current_method_name
						
						# 2. if context is unknown, check if we're in constructor
						if current_method_name.nil?
							# check if super() call is in first line of constructor
							# by analyzing instance variables count and statement type in method body
							if instance[:instance_vars].size <= 1
								current_method_name = "konstruktor"
							else
								# if we can't determine context, block execution
								Utils.runtime_error("Nie można określić kontekstu metody dla wywołania 'super()'", node.line)
							end
						end
					else
						# use explicitly provided method name
						current_method_name = node.method_name
					end
					
					# find method in parent class
					method_result = env.find_parent_method(instance, current_method_name)
					Utils.runtime_error("Nie znaleziono metody #{current_method_name} w klasie nadrzędnej", node.line) unless method_result
					
					method_info = method_result[:method_info]
					
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
							"Metoda #{current_method_name} oczekiwała, a minimum #{min_args} argumentów, otrzymała #{arguments.size}",
							node.line
						)
					end
					
					unless rest_param
						if arguments.size > max_args
							Utils.runtime_error(
								"Metoda #{current_method_name} oczekiwała, a maksymalnie #{max_args} argumentów, otrzymała #{arguments.size}",
								node.line
							)
						end
					end
					
					# create new environment for method
					method_env = method_info[:env].new_env
					method_env.set_instance(instance)  # use current instance
					
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
					
					# execute method body
					begin
						# keep current method context so nested super calls work correctly
						Utils::ContextTracker.track_method_call(current_method_name) do
							interpret!(method_info[:declaration].body_statement, method_env)
						end
						result = [:type_null, Utils::NULL_VALUE]  # by default return 'nic'
					rescue Utils::ReturnError => e
						result = e.value  # or specific value returned by method
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
						Utils.runtime_error("Statyczna stała #{class_name}.#{node.name} została, a już zdefiniowana i nie może być zmieniona", node.line)
					end

					value_type, value_value = interpret!(node.value, env)
					env.set_static_var(node.class_name, node.name, value_value, value_type)
					
					[value_type, value_value]
				elsif node.is_a? AST::StaticMethodCall
					# get class definition
					class_def = env.get_class(node.class_name)
					Utils.runtime_error("Nieznana klasa #{node.class_name}", node.line) unless class_def

					if env.built_in_methods.get_method(:type_class, node.method_name)
						# prepare arguments
						evaluated_args = node.arguments.map { |arg| interpret!(arg, env)[1] }
						
						# add class name
						class_with_name = class_def.dup
						class_with_name[:name] = node.class_name
						
						# call method
						result = env.call_method(:type_class, node.method_name, class_with_name, evaluated_args)

						# return bool type
						if result.is_a?(Array) && result.size == 2 && result[0].is_a?(Symbol)
							return result 
						end
						
						# convert result
						result_type = case result
													when Integer then :type_int
													when Float then :type_float
													when String then :type_string
													when TrueClass, FalseClass then :type_bool
													when Array then :type_array
													when NilClass then :type_null
													when Hash then :type_object
													else :type_object
													end
						
						return [result_type, result]
					end

					# ── Native static method dispatch ──
            if class_def[:native]
              native_static = class_def[:native_static_methods]
              if native_static && native_static.key?(node.method_name)
                arguments = node.arguments.map { |arg| interpret!(arg, env) }

                begin
                  result = Utils::NativeClassRegistry.dispatch_static_method(
                    node.class_name, node.method_name, arguments
                  )
                rescue => e
                  Utils.runtime_error(
                    "Błąd metody statycznej #{node.method_name} klasy #{node.class_name}: #{e.message}",
                    node.line
                  )
                end

                return result
              end

              Utils.runtime_error(
                "Nieznana metoda statyczna '#{node.method_name}' w klasie #{node.class_name}",
                node.line
              )
            end
					
					# look for static method in whole class hierarchy
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

					Utils.runtime_error("Nieznana metoda statyczna '#{node.method_name}' w klasie #{node.class_name}", node.line) unless method_info
					
					# evaluate arguments
					arguments = node.arguments.map do |arg|
						interpret!(arg, env)
					end
					
					# check argument count
					params = method_info[:declaration].params
					
					# handle rest type parameters
					rest_param = params.find(&:rest?)
					min_args = params.count { |p| !p.has_default? && !p.rest? }
					max_args = rest_param ? Float::INFINITY : params.size
					
					if arguments.size < min_args
						Utils.runtime_error(
							"Metoda statyczna '#{node.method_name}' oczekiwała, a minimum #{min_args} argumentów, otrzymała #{arguments.size}",
							node.line
						)
					end
					
					unless rest_param
						if arguments.size > max_args
							Utils.runtime_error(
								"Metoda statyczna '#{node.method_name}' oczekiwała, a maksymalnie #{max_args} argumentów, otrzymała #{arguments.size}",
								node.line
							)
						end
					end
					
					# create new environment for static method
					method_env = method_info[:env].__getobj__.new_env
					
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
							Utils.runtime_error("Brakujący argument '#{param.name}'", node.line)
						end
					end
					
					# handle rest parameter
					if rest_param
						rest_args = arguments[rest_position..-1] || []
						rest_array_elements = rest_args.map { |arg| { type: arg[0], value: arg[1] } }
						method_env.set_local_var(rest_param.name, rest_array_elements, :type_array)
					end
					
					# execute static method body
					Utils::ContextTracker.current_class_name = node.class_name
					Utils::CallStackTracker.push(:method, node.method_name, @current_file, node.line)
					begin
						interpret!(method_info[:declaration].body_statement, method_env)
						result = [:type_null, Utils::NULL_VALUE]
					rescue Utils::ReturnError => e
						result = e.value
					ensure
						Utils::CallStackTracker.pop 
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
					result = Utils::RubyEvaluator.safe_call(module_path, method_name, args, @current_file)
					[result[:type], result[:value]]
				elsif node.is_a? AST::RubyCallStmt
					interpret!(node.expression, env)
				elsif node.is_a? AST::RequireRubyStmt
					begin
						success = Utils::RubyEvaluator.require_library(node.library_name, @current_file)
						[:type_bool, success ? Utils::Utils::BOOL_TRUE : Utils::Utils::BOOL_FALSE]
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
				rescue Utils::AlexScriptError => e
					raise e
				rescue StandardError => e
					# translate and re-raise
					alex_error = Utils::ExceptionsTranslator.translate(e)
					raise alex_error
				end
			end
    end
  end
end
