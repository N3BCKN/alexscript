# frozen_string_literal: true

module AlexScript
	module AST
  	# proba "{" <body_stmts> "}" zlap "{" <body_stmts> "}" wkoncu? "{" <body_stmts>"}"
  	class TryCatchStmt < Stmt
    	attr_reader :try_block, :catch_blocks, :finally_block, :line
      	
			def initialize(try_block, catch_blocks, finally_block, line)
        validate_types([try_block], Stmts)
        validate_types([finally_block], Stmts) if finally_block
        validate_types(catch_blocks, CatchBlock)
  
        @try_block = try_block
        @catch_blocks = catch_blocks || []
        @finally_block = finally_block
        @line = line
      end

      def evaluate(interpreter, env)
        interpreter.handle_try_catch_statement(self, env)
      end
            
      def pretty_print(level = 0)
      	result = ["#{indent(level)}TryCatchStmt(", 
        	"#{indent(level+1)}Try:", 
          @try_block.pretty_print(level+2)]
              
          unless @catch_blocks.empty?
          	result << "#{indent(level+1)}Catch:"
            @catch_blocks.each do |catch_block|
            	result << catch_block.pretty_print(level+2)
            end
          end
              
          if @finally_block
            result << "#{indent(level+1)}Finally:"
            result << @finally_block.pretty_print(level+2)
          end
              
          result << "#{indent(level)})"
          result.join("\n")
    	end
		end

		# proba "{" <body_stmts> "}" zlap "{" <body_stmts> "}"
		class CatchBlock < Node
      attr_reader :exception_var, :body, :exception_type, :line
      
      def initialize(exception_var, body, exception_type, line)
        validate_types([exception_var], String)
        validate_types([body], Stmts)
        validate_types([exception_type], Identifier) if exception_type

        @exception_var = exception_var
        @body = body
        @exception_type = exception_type
        @line = line
      end
      
      def pretty_print(level = 0)
        type_str = @exception_type ? " as #{@exception_type.pretty_print(0)}" : ""
        [
          "#{indent(level)}CatchBlock(#{@exception_var}#{type_str}",
          @body.pretty_print(level+1),
          "#{indent(level)})"
        ].join("\n")
      end
    end

		# rzuc "{" <body_stmts> "}"
    class ThrowStmt < Stmt
      attr_reader :expression, :exception_type, :line
    
      def initialize(expression, exception_type = nil, line)
        validate_types([expression], Expr)
        validate_types([exception_type], String) if exception_type

        @expression = expression      # Wyrażenie (wiadomość) lub nil
        @exception_type = exception_type  # Typ wyjątku lub nil
        @line = line
      end

      def evaluate(interpreter, env)
        interpreter.handle_throw_statement(self, env)
      end
      
      def pretty_print(level = 0)
        if @exception_type
          [
            "#{indent(level)}ThrowStmt(#{@exception_type}:",
            @expression.pretty_print(level+1),
            "#{indent(level)})"
          ].join("\n")
        else
          [
            "#{indent(level)}ThrowStmt(",
            @expression.pretty_print(level+1),
            "#{indent(level)})"
          ].join("\n")
        end
      end
    end
	end
end