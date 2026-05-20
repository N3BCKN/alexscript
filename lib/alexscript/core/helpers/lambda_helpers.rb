# frozen_string_literal: true

# all methods responsible for handling anonymous functions (fn) and higher order methods such as mapuj, filtruj etc

# higher order methods are placed here instead of Utils::Methods section as they require direct access to interpreter 

module AlexScript
  module Core
    module Helpers
      module LambdaHelper

        SORTABLE_TYPES = %i[type_int type_float type_string].freeze

        # function value invocation helper 
        # lightweight caller for fn values, used by HOF array methods.
        # typed_args is an array of [type, value] pairs.
        def invoke_function_value(func_value, typed_args, env, line)
          func_declr = func_value[:declaration]
          func_env = func_value[:env]

          new_env = func_env.new_env

          # Propagate instance context for fn used inside class methods
          current_instance = env.get_instance
          new_env.set_instance(current_instance) if current_instance

          # Bind parameters — fast path for common 1-2 arg case
          params = func_declr.params
          params.each_with_index do |param, idx|
            if idx < typed_args.size
              new_env.set_local_var(param.name, typed_args[idx][1], typed_args[idx][0])
            elsif param.has_default?
              default_val = interpret!(param.default_value, func_env)
              new_env.set_local_var(param.name, default_val[1], default_val[0])
            end
          end

          # Execute body
          if func_declr.respond_to?(:implicit_return?) && func_declr.implicit_return?
            interpret!(func_declr.body_statement.stmts[0].expression, new_env)
          else
            catch(:alex_return) do
              interpret!(func_declr.body_statement, new_env)
              [:type_null, Utils::NULL_VALUE]
            end
          end
        end

        # Higher-order array methods 
        # Handles: mapuj, filtruj, redukuj, kazdy, znajdz, dowolny, wszystkie, sortuj
        def interpret_array_hof(method_name, array, node, env)
          # sortuj can work without fn (natural sort) or with fn (comparator)
          if method_name == 'sortuj' && node.arguments.empty?
            return interpret_array_sort_natural(array, node)
          end
  
          # All other HOF methods require a function argument
          unless node.arguments.size >= 1
            Utils.runtime_error("Metoda #{method_name} wymaga funkcji jako argumentu", node.line)
          end
  
          fn_type, fn_value = interpret!(node.arguments[0], env)
          unless fn_type == :type_function
            Utils.runtime_error("Argument metody #{method_name} musi być funkcją", node.line)
          end
  
          # Check if fn accepts index as second param (for mapuj)
          fn_param_count = fn_value[:declaration].params.size
  
          case method_name
          when 'mapuj'
            result = Array.new(array.size)
            array.each_with_index do |elem, idx|
              args = [[ elem[:type], elem[:value] ]]
              args << [:type_int, idx] if fn_param_count >= 2
              res_type, res_value = invoke_function_value(fn_value, args, env, node.line)
              result[idx] = { type: res_type, value: res_value }
            end
            [:type_array, result]
  
          when 'filtruj'
            result = []
            array.each do |elem|
              args = [[ elem[:type], elem[:value] ]]
              args << [:type_int, result.size] if fn_param_count >= 2
              res_type, res_value = invoke_function_value(fn_value, args, env, node.line)
              if is_truthy?(res_type, res_value, node.line)
                result << elem
              end
            end
            [:type_array, result]
  
          when 'redukuj'
            # Second argument is initial value
            unless node.arguments.size >= 2
              Utils.runtime_error("Metoda redukuj wymaga wartości początkowej jako drugiego argumentu", node.line)
            end
            acc_type, acc_value = interpret!(node.arguments[1], env)
  
            array.each do |elem|
              args = [
                [acc_type, acc_value],
                [elem[:type], elem[:value]]
              ]
              acc_type, acc_value = invoke_function_value(fn_value, args, env, node.line)
            end
            [acc_type, acc_value]
  
          when 'kazdy'
            array.each_with_index do |elem, idx|
              args = [[ elem[:type], elem[:value] ]]
              args << [:type_int, idx] if fn_param_count >= 2
              invoke_function_value(fn_value, args, env, node.line)
            end
            [:type_null, Utils::NULL_VALUE]
  
          when 'znajdz'
            array.each do |elem|
              args = [[ elem[:type], elem[:value] ]]
              res_type, res_value = invoke_function_value(fn_value, args, env, node.line)
              if is_truthy?(res_type, res_value, node.line)
                return [elem[:type], elem[:value]]
              end
            end
            [:type_null, Utils::NULL_VALUE]
  
          when 'dowolny'
            array.each do |elem|
              args = [[ elem[:type], elem[:value] ]]
              res_type, res_value = invoke_function_value(fn_value, args, env, node.line)
              if is_truthy?(res_type, res_value, node.line)
                return [:type_bool, Utils::BOOL_TRUE]
              end
            end
            [:type_bool, Utils::BOOL_FALSE]
  
          when 'wszystkie'
            array.each do |elem|
              args = [[ elem[:type], elem[:value] ]]
              res_type, res_value = invoke_function_value(fn_value, args, env, node.line)
              unless is_truthy?(res_type, res_value, node.line)
                return [:type_bool, Utils::BOOL_FALSE]
              end
            end
            [:type_bool, Utils::BOOL_TRUE]
  
          when 'sortuj'
            sorted = array.sort do |a, b|
              args = [
                [a[:type], a[:value]],
                [b[:type], b[:value]]
              ]
              res_type, res_value = invoke_function_value(fn_value, args, env, node.line)
              Utils.runtime_error("Komparator sortuj musi zwracać liczbę", node.line) unless [:type_int, :type_float].include?(res_type)
              res_value
            end
            [:type_array, sorted]
  
          else
            Utils.runtime_error("Nieznana metoda wyższego rzędu: #{method_name}", node.line)
          end
        end


        # Natural sort (no comparator fn) — sorts numbers and strings
        def interpret_array_sort_natural(array, node)
          sorted = array.sort do |a, b|
            if a[:type] == b[:type] && SORTABLE_TYPES.include?(a[:type])
              a[:value] <=> b[:value]
            else
              Utils.runtime_error("Nie można porównać elementów typu #{a[:type]} i #{b[:type]} — użyj komparatora fn", node.line)
            end
          end
          [:type_array, sorted]
        end

      end 
    end 
  end 
end