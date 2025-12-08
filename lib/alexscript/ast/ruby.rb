# frozen_string_literal: true

module AlexScript
    module AST
      class RubyCall < Expr
        attr_reader :module_path, :method_name, :arguments, :line
        
        def initialize(module_path, method_name, arguments, line)
          @module_path = module_path
          @method_name = method_name
          @arguments = arguments
          @line = line
        end
        
        def pretty_print(level = 0)
          "RubyCall(#{@module_path}::#{@method_name}(#{@arguments.map(&:pretty_print).join(', ')}))"
        end
      end

      class RubyCallStmt < Stmt
        attr_reader :expression
        
        def initialize(expression, line)
          validate_types([expression], RubyCall)
          @expression = expression
          @line = line
        end
        
        def pretty_print(indent = 0)
          spaces = ' ' * indent
          "#{spaces}RubyCallStmt(\n#{@expression.pretty_print(indent + 2)}\n#{spaces})"
        end
      end

      class RequireRubyStmt < Stmt
        attr_reader :library_name
        
        def initialize(library_name, line)
          @library_name = library_name
          @line = line
        end
        
        def pretty_print(indent = 0)
          spaces = ' ' * indent
          "#{spaces}RequireRuby(#{@library_name})"
        end
      end
			
			class RubyObjCall < Expr
				attr_reader :object, :method_name, :arguments, :line
				
				def initialize(object, method_name, arguments, line)
					validate_types([object], Expr)
					@object = object
					@method_name = method_name
					@arguments = arguments
					@line = line
				end
				
				def pretty_print(indent = 0)
					spaces = ' ' * indent
					"#{spaces}RubyObjCall(\n" +
					"#{spaces}  object: #{@object.pretty_print(indent + 2)},\n" +
					"#{spaces}  method: #{@method_name},\n" +
					"#{spaces}  args: [#{@arguments.map { |arg| arg.pretty_print(indent + 4) }.join(', ')}]\n" +
					"#{spaces})"
				end
			end
			
			class RubyObjCallStmt < Stmt
				attr_reader :expression
				
				def initialize(expression, line)
					validate_types([expression], Expr)
					@expression = expression
					@line = line
				end
				
				def pretty_print(indent = 0)
					spaces = ' ' * indent
					"#{spaces}RubyObjCallStmt(\n#{@expression.pretty_print(indent + 2)}\n#{spaces})"
				end
			end
    end
  end