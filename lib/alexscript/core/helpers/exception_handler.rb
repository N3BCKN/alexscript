# frozen_string_literal: true

# Handles throwing and catching exceptions
# Converts exception instances to Ruby exceptions, manages catch block matching
# with inheritance support, and creates exception objects for catch variables

module AlexScript
  module Core
    module Helpers
      module ExceptionHandler
        # ========================================================================
        # UPDATED: Handle ThrowStmt with class instantiation
        # ========================================================================
          
        def handle_throw_statement(node, env)
          # Case 1: Old object syntax - rzuc { typ: "BladTypu", wiadomosc: "..." }
          if node.exception_type
            message_type, message_value = interpret!(node.expression, env)
            exception_class = @exception_registry[node.exception_type]
            
            if exception_class.nil?
              Utils.runtime_error("Nieznany typ wyjątku: #{node.exception_type}", node.line)
            end
            
            raise exception_class.new(message_value, node.line)
            
          # Case 2: Direct string - rzuc "Błąd"  
          elsif node.expression.is_a?(AST::Str)
            message = node.expression.value
            raise Utils::WyjatekPodstawowy.new(message, node.line)
            
          # Case 3: NEW - Class instantiation - rzuc BladTypu.nowy("...")
          elsif node.expression.is_a?(AST::ClassInstantiation)
            handle_exception_instantiation_throw(node.expression, env, node.line)
            
          # Case 4: Expression that evaluates to instance
          else
            expr_type, expr_value = interpret!(node.expression, env)
            
            if expr_type == :type_instance
              # Check if it's an exception instance
              if env.is_exception_class?(expr_value[:class_name])
                raise_exception_from_instance(expr_value, env, node.line)
              else
                Utils.runtime_error(
                  "Nie można rzucić instancją klasy #{expr_value[:class_name]} - nie jest wyjątkiem",
                  node.line
                )
              end
            elsif expr_type == :type_string
              raise Utils::WyjatekPodstawowy.new(expr_value, node.line)
            elsif expr_type == :type_object
              # Old object format fallback
              exception_type = expr_value['typ']
              exception_message = expr_value['wiadomosc'] || ""
              exception_class = @exception_registry[exception_type] || Utils::WyjatekPodstawowy
              raise exception_class.new(exception_message, node.line)
            else
              Utils.runtime_error(
                "Nieprawidłowy typ dla rzuc: oczekiwano napis, instancję wyjątku lub obiekt",
                node.line
              )
            end
          end
        end
        
        # ========================================================================
        # NEW: Handle throwing exception via class instantiation
        # ========================================================================
        
        def handle_exception_instantiation_throw(instantiation_node, env, throw_line)
          class_name = instantiation_node.class_name
          
          # Verify it's an exception class
          unless env.is_exception_class?(class_name)
            Utils.runtime_error(
              "Klasa #{class_name} nie jest wyjątkiem",
              throw_line
            )
          end
          
          # Create the exception instance (reuse existing logic)
          instance_type, instance = interpret!(instantiation_node, env)
          
          # Now raise it as Ruby exception
          raise_exception_from_instance(instance, env, throw_line)
        end
        
        # ========================================================================
        # NEW: Convert AlexScript exception instance to Ruby exception
        # ========================================================================
        
        def raise_exception_from_instance(instance, env, line)
          class_name = instance[:class_name]
          class_def = env.get_class(class_name)
          
          # Get message from @wiadomosc instance variable
          message_var = instance[:instance_vars]['wiadomosc']
          message = message_var ? message_var[1] : "Błąd"
          
          # Determine which Ruby exception class to use
          ruby_class_name = env.determine_ruby_exception_class(class_name, class_def)
          
          # Get the actual Ruby class
          ruby_exception_class = Object.const_get("AlexScript::#{ruby_class_name}")
          
          # Create and raise the exception with metadata
          exception = ruby_exception_class.new(message, line)
          
          # Attach AlexScript class info for catch blocks
          exception.instance_variable_set(:@alexscript_class_name, class_name)
          exception.instance_variable_set(:@alexscript_instance, instance)
          
          raise exception
        end
        
        # ========================================================================
        # UPDATED: Handle TryCatchStmt - match by AlexScript class
        # ========================================================================
        
        # Update existing try-catch handling to check AlexScript class names
        def handle_try_catch_statement(node, env)
          try_env = env.new_env
          
          begin
            interpret!(node.try_block, try_env)
          rescue StandardError => e
            caught = false
            
            node.catch_blocks.each do |catch_block|
              if catch_block.exception_type
                # Get the AlexScript exception type name
                type_name = catch_block.exception_type.name
                
                # NEW: Check if exception has AlexScript class info
                if e.instance_variable_defined?(:@alexscript_class_name)
                  alexscript_class = e.instance_variable_get(:@alexscript_class_name)
                  
                  # Check if caught exception matches or inherits from catch type
                  if alexscript_class == type_name || 
                    env.is_subclass_of(alexscript_class, type_name)
                    caught = true
                    execute_catch_block(catch_block, e, env)
                    break
                  end
                  
                # OLD: Fallback to Ruby class matching (for old-style exceptions)
                else
                  exception_class = @exception_registry[type_name]
                  if exception_class && e.is_a?(exception_class)
                    caught = true
                    execute_catch_block(catch_block, e, env)
                    break
                  end
                end
                
              else
                # Catch all - no type specified
                caught = true
                execute_catch_block(catch_block, e, env)
                break
              end
            end
            
            # Re-raise if not caught
            raise e unless caught
          ensure
            # Execute finally block if exists
            interpret!(node.finally_block, env.new_env) if node.finally_block
          end
        end
        
        # ========================================================================
        # NEW: Execute catch block with exception info
        # ========================================================================
        
        def execute_catch_block(catch_block, exception, env)
          catch_env = env.new_env
          
          # Create exception object for catch variable
          exception_obj = create_exception_object(exception)
          
          catch_env.set_local_var(
            catch_block.exception_var,
            exception_obj,
            :type_object
          )
          
          # Execute catch block body
          interpret!(catch_block.body, catch_env)
        end
        
        # ========================================================================
        # NEW: Create exception object for catch variable
        # ========================================================================
        
        def create_exception_object(exception)
          obj = {}
          
          # Basic fields (always present)
          obj['wiadomosc'] = {
            type: :type_string,
            value: exception.message
          }
          
          obj['typ'] = {
            type: :type_string,
            value: exception.class.name.split('::').last
          }
          
          obj['linia'] = {
            type: :type_int,
            value: exception.respond_to?(:line) ? exception.line : nil
          }
          
          # NEW: Add AlexScript class name if available
          if exception.instance_variable_defined?(:@alexscript_class_name)
            obj['klasa'] = {
              type: :type_string,
              value: exception.instance_variable_get(:@alexscript_class_name)
            }
          end
          
          # NEW: Add instance reference if available
          if exception.instance_variable_defined?(:@alexscript_instance)
            instance = exception.instance_variable_get(:@alexscript_instance)
            obj['instancja'] = {
              type: :type_instance,
              value: instance
            }
          end
          
          obj
        end
      end
    end
  end 
end 