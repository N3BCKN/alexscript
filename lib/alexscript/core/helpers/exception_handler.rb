# frozen_string_literal: true

# Handles throwing and catching exceptions
# Converts exception instances to Ruby exceptions, manages catch block matching
# with inheritance support, and creates exception objects for catch variables

module AlexScript
  module Core
    module Helpers
      module ExceptionHandler
        # ========================================================================
        # Handle ThrowStmt with class instantiation
        # ========================================================================
          
        def handle_throw_statement(node, env)
          if node.expression.is_a?(AST::ClassInstantiation)
            # rzuc BladTypu.nowy("message")
            handle_exception_instantiation_throw(node.expression, env)
          elsif node.expression.is_a?(AST::Str)
            # rzuc "simple string message"
            # Use BladWykonania as default exception class
            exception_class_def = env.get_class('BladWykonania')
            
            unless exception_class_def
              Utils.runtime_error("Nie znaleziono klasy wyjątku BladWykonania", node.line)
            end
            
            instance = {
              class_name: 'BladWykonania',
              instance_vars: {
                'wiadomosc' => [:type_string, node.expression.value]
              },
              class_def: exception_class_def
            }
            
            raise_exception_from_instance(instance, env, node.line)
          else
            # Evaluate expression and handle
            expr_type, expr_value = interpret!(node.expression, env)
            
            if expr_type == :type_string
              # Simple string throw - use BladWykonania
              exception_class_def = env.get_class('BladWykonania')
              
              unless exception_class_def
                Utils.runtime_error("Nie znaleziono klasy wyjątku BladWykonania", node.line)
              end
              
              instance = {
                class_name: 'BladWykonania',
                instance_vars: {
                  'wiadomosc' => [:type_string, expr_value]
                },
                class_def: exception_class_def
              }
              
              raise_exception_from_instance(instance, env, node.line)
            else
              Utils.runtime_error("Nieprawidłowy typ dla rzuc: oczekiwano string lub instancję wyjątku", node.line)
            end
          end
        end
        
        # ========================================================================
        # Handle throwing exception via class instantiation
        # ========================================================================
        
        def handle_exception_instantiation_throw(node, env)
          class_name = node.class_name
          
          # Get exception class definition
          exception_class_def = env.get_class(class_name)
          
          unless exception_class_def
            Utils.runtime_error("Nieznana klasa wyjątku: #{class_name}", node.line)
          end
          
          # Check if it's an exception class
          unless env.is_exception_class?(class_name)
            Utils.runtime_error("Klasa #{class_name} nie jest wyjątkiem", node.line)
          end
          
          # Evaluate constructor arguments
          message = if node.arguments.empty?
                      "Exception"
                    else
                      arg_type, arg_value = interpret!(node.arguments[0], env)
                      arg_value.to_s
                    end
          
          # Create exception instance
          instance = {
            class_name: class_name,
            instance_vars: {
              'wiadomosc' => [:type_string, message]
            },
            class_def: exception_class_def
          }
          
          # Raise with line number
          raise_exception_from_instance(instance, env, node.line)  # <-- DODAJ node.line
        end
        
        # ========================================================================
        # Convert AlexScript exception instance to Ruby exception
        # ========================================================================
        
        def raise_exception_from_instance(instance, env, line)
          class_name = instance[:class_name]
          message = instance[:instance_vars]['wiadomosc']&.last || "Unknown error"
          
          # Create a Ruby exception to raise
          # We use a generic wrapper instead of specific exception classes
          ruby_exception = RuntimeError.new(message)
          
          # Attach metadata for stack trace
          ruby_exception.instance_variable_set(:@alexscript_class_name, class_name)
          ruby_exception.instance_variable_set(:@alexscript_instance, instance)
          ruby_exception.instance_variable_set(:@call_stack, Utils::CallStackTracker.current_stack)
          
          # Define accessor methods
          ruby_exception.define_singleton_method(:alexscript_class_name) do
            @alexscript_class_name
          end
          
          ruby_exception.define_singleton_method(:alexscript_instance) do
            @alexscript_instance
          end
          
          ruby_exception.define_singleton_method(:call_stack) do
            @call_stack
          end
          
          raise ruby_exception
        end
        
        # ========================================================================
        # Handle TryCatchStmt - match by AlexScript class
        # ========================================================================
        
        # Update existing try-catch handling to check AlexScript class names
        def handle_try_catch_statement(node, env)
          try_env = env.new_env
          
          begin
            interpret!(node.try_block, try_env)
          rescue Utils::ReturnError, Utils::BreakException, Utils::ContinueException
            raise
          rescue StandardError => e
            caught = false
            
            node.catch_blocks.each do |catch_block|
              if catch_block.exception_type
                # Get the AlexScript exception type name
                type_name = catch_block.exception_type.is_a?(AST::ModuleAccess) ?
                catch_block.exception_type.member_name : catch_block.exception_type.name
                
                # Check if exception has AlexScript class info
                if e.instance_variable_defined?(:@alexscript_class_name)
                  alexscript_class = e.instance_variable_get(:@alexscript_class_name)
                  
                  # Check if caught exception matches or inherits from catch type
                  if alexscript_class == type_name || 
                    env.is_subclass_of(alexscript_class, type_name)
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
        # Execute catch block with exception info
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
        # Create exception object for catch variable
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
          
          # Add AlexScript class name if available
          if exception.instance_variable_defined?(:@alexscript_class_name)
            obj['klasa'] = {
              type: :type_string,
              value: exception.instance_variable_get(:@alexscript_class_name)
            }
          end
          
          # Add instance reference if available
          if exception.instance_variable_defined?(:@alexscript_instance)
            instance = exception.instance_variable_get(:@alexscript_instance)
            obj['instancja'] = {
              type: :type_instance,
              value: instance
            }
          end

					if exception.instance_variable_defined?(:@call_stack)
            stack = exception.instance_variable_get(:@call_stack)
            formatted_stack = Utils::CallStackTracker.format_stack(stack)
            
            # Convert to AlexScript array of strings
            stack_array = formatted_stack.map do |frame_str|
              { type: :type_string, value: frame_str }
            end
            
            obj['stos'] = {
              type: :type_array,
              value: stack_array
            }
          end
          
          obj
        end
      end
    end
  end 
end 