# frozen_string_literal: true

module AlexScript
  module Core
    # parser class that builds an AST from tokens using recursive descent parsing
    # implements grammar rules for expressions, handling operator precedence and grouping
    class Parser
      def initialize(tokens)
        @tokens = tokens
        @current = 0
				@inside_class_body = false
        @current_module_path = []
      end

      # advances the parser position and returns current token
      def advance
        token = @tokens[@current]
        @current += 1
        token
      end

      # returns current token without advancing position
      def peek
        @tokens[@current]
      end

      def peek_next
        return nil if @current + 1 >= @tokens.length

        @tokens[@current + 1]
      end

      # checks if next token matches expected type
      def next?(expected_type)
        return false if @current >= @tokens.length

        peek.token_type == expected_type
      end

      # expects a token of specific type, raises error if not found
      def expect(expected_type)
        if @current >= @tokens.length
          Utils.parse_error("Znaleziono '#{previous_token.lexeme}' na koncu parsowania", previous_token.line)
        elsif peek.token_type == expected_type
          advance
        else
          Utils.parse_error("Oczekiwano '#{expected_type}', znaleziono '#{peek.lexeme}'", peek.line)
        end
      end

      # returns the previously consumed token
      def previous_token
        @tokens[@current - 1]
      end

      # matches and consumes token if it matches expected type
      def match(expected_type)
        return false if @current >= @tokens.length
        return false if peek.token_type != expected_type

        @current += 1 # Consume the token on match
        true
      end

      # <primary> ::= <integer> | <float> | '(' <expr> ')' | <bool> | <string> | <identifier>
      # mandles basic expressions and parenthesized expressions
      def primary
        return AST::Int.new(previous_token.lexeme.to_i, previous_token.line) if match(:tok_int)
        return AST::Flt.new(previous_token.lexeme.to_f, previous_token.line) if match(:tok_float)
        return AST::Bool.new(previous_token.lexeme, previous_token.line) if match(:tok_true) || match(:tok_false)
        return AST::Str.new(previous_token.lexeme.to_s, previous_token.line) if match(:tok_string)
        return AST::Null.new(previous_token.line) if match(:tok_null)
        return array_statement if match(:tok_lsquare)
        return input_statement if match(:tok_input)

        if match(:tok_instance_var)
          return AST::InstanceVariable.new(previous_token.lexeme, previous_token.line)
        end

        if match(:tok_self)
          expr = AST::SelfReference.new(previous_token.line)
          
          # obsługa method calls i array access na 'sam'
          loop do
            if match(:tok_dot)
              method_name = parse_method_name
              arguments = []
              
              if match(:tok_lparen)
                unless next?(:tok_rparen)
                  loop do
                    arguments << expression
                    break unless match(:tok_comma)
                  end
                end
                expect(:tok_rparen)
                expr = AST::MethodCall.new(expr, method_name, arguments, previous_token.line)
              else
                # wywołanie metody bez nawiasów (np. sam.klasa)
                expr = AST::MethodCall.new(expr, method_name, [], previous_token.line)
              end
            elsif match(:tok_lsquare)
              # obsługa sam[key] jeśli kiedyś będzie potrzebne
              key = expression
              expect(:tok_rsquare)
              expr = AST::ObjectOrArrayAccess.new(expr, key, previous_token.line)
            else
              break
            end
          end
          
          return expr
        end

        if match(:tok_lparen)
          expr = expression
          Utils.parse_error("Oczekiwano ')' po wyrazeniu", previous_token.line) unless match(:tok_rparen)
          return AST::Grouping.new(expr, previous_token.line)
        end

        if match(:tok_ruby)
          return ruby_call
        elsif match(:tok_ruby_obj)
          return ruby_obj_call
        end

        if match(:tok_super)
          return super_expression
        end

        if match(:tok_lcurly)
          pairs = {}

          unless next?(:tok_rcurly)
            loop do
              key = expect(:tok_string)
              expect(:tok_colon)
              value = expression
              pairs[key.lexeme] = value

              break unless match(:tok_comma)
            end
          end

          expect(:tok_rcurly)
          return AST::ObjectLiteral.new(pairs, previous_token.line)
        end

        identifier = expect(:tok_identifier)

        # check for module path TYLKO jeśli następny token to ::
        # (nie w kontekście wywołania funkcji/metody)
        if next?(:tok_double_colon)
          module_path = [-identifier.lexeme]

          while match(:tok_double_colon)
              next_id = expect(:tok_identifier)
              module_path << -next_id.lexeme
            end
            
            member_name = module_path.pop
            
            if module_path.empty?
              Utils.parse_error("Nieprawidłowa składnia modułu", identifier.line)
            end
            
            # Modul::Klasa.nowy()
            if match(:tok_dot)
              method = expect(:tok_identifier).lexeme
              if method == "nowy" && match(:tok_lparen)
                arguments = []
                unless next?(:tok_rparen)
                  loop do
                    arguments << expression
                    break unless match(:tok_comma)
                  end
                end
                expect(:tok_rparen)
                return AST::ModuleClassInstantiation.new(module_path, member_name, arguments, identifier.line)
              else
                Utils.parse_error("Nieoczekiwana metoda #{method} po dostępie do modułu", identifier.line)
              end
            end
            
            # NOWE: Modul::funkcja(args) - wywołanie funkcji modułowej
            if match(:tok_lparen)
              arguments = []
              unless next?(:tok_rparen)
                loop do
                  arguments << expression
                  break unless match(:tok_comma)
                end
              end
              expect(:tok_rparen)
              
              # zwróć ModuleFunctionCall zamiast ModuleAccess
              return AST::ModuleFunctionCall.new(module_path, member_name, arguments, identifier.line)
            end
            
            # Modul::STALA (bez wywołania)
            return AST::ModuleAccess.new(module_path, member_name, identifier.line)
          end

        # check static variable: ClassName.CONSTANT_VARIABLE
        if next?(:tok_dot) && peek_next && peek_next.token_type == :tok_identifier && 
          peek_next.lexeme.match?(/^[A-Z_]+$/) && identifier.lexeme.match?(/^[A-Z]/)
          advance
          static_var_name = expect(:tok_identifier).lexeme
          return AST::StaticVariable.new(identifier.lexeme, static_var_name, identifier.line)
        end

        # normal identifier processing
        expr = AST::Identifier.new(identifier.lexeme, identifier.line)

        loop do
          if match(:tok_lparen)
            f_args = []
            unless next?(:tok_rparen)  # <-- parsuj argumenty TUTAJ bezpośrednio
              loop do
                f_args << expression
                break unless match(:tok_comma)
              end
            end
            expect(:tok_rparen)
            expr = AST::FuncCall.new(identifier.lexeme, f_args, previous_token.line)
            break
          elsif match(:tok_lsquare)
            key = expression
            expect(:tok_rsquare)

            if match(:tok_assign)
              value = expression
              expr = AST::ObjectOrArrayAssignment.new(expr, key, value, identifier.line)
              break
            else
              expr = AST::ObjectOrArrayAccess.new(expr, key, identifier.line)
            end
          elsif match(:tok_dot)
            method_name = parse_method_name
            arguments = []
            
            if method_name == "nowy" && match(:tok_lparen)
              unless next?(:tok_rparen)
                loop do
                  arguments << expression
                  break unless match(:tok_comma)
                end
              end
              expect(:tok_rparen)
              expr = AST::ClassInstantiation.new(identifier.lexeme, arguments, previous_token.line)
            else 
              if match(:tok_lparen)
                unless next?(:tok_rparen)
                  loop do
                    arguments << expression
                    break unless match(:tok_comma)
                  end
                end
                expect(:tok_rparen)
                
                if expr.is_a?(AST::Identifier) && 
                   identifier.lexeme[0] >= 'A' && identifier.lexeme[0] <= 'Z' && 
                   !["String", "Number", "Array", "Object", "Boolean"].include?(identifier.lexeme)
                  expr = AST::StaticMethodCall.new(identifier.lexeme, method_name, arguments, previous_token.line)
                  break
                else
                  expr = AST::MethodCall.new(expr, method_name, arguments, identifier.line)
                end
              else
                expr = AST::MethodCall.new(expr, method_name, arguments, identifier.line)
              end
            end 
          else
            break
          end
        end

        expr
      end

      def super_expression
				token_line = previous_token.line
				
				if match(:tok_lparen)  # super()
					args = arguments
					expect(:tok_rparen)
					# create SuperMethodCall node without explicitly provided method name
					# nil in method_name place means current method should be used
					return AST::SuperMethodCall.new(nil, args, token_line)
				elsif match(:tok_dot)  # super.metoda()
					method_name = parse_method_name
					expect(:tok_lparen)
					args = arguments
					expect(:tok_rparen)
					# here we provide specific method name from parent class
					return AST::SuperMethodCall.new(method_name, args, token_line)
				else
					Utils.parse_error("Oczekiwano '(' lub '.' po 'super'", token_line)
				end
			end

      def ruby_call      
        expect(:tok_lparen)
        
        # first argument is module path
        module_path_token = expect(:tok_string)
        module_path = module_path_token.lexeme
        
        expect(:tok_comma)
        
        # second argument is method name
        method_name_token = expect(:tok_string)
        method_name = method_name_token.lexeme
        
        # remaining arguments are call parameters
        arguments = []
        if match(:tok_comma)
          loop do
            arguments << expression
            break unless match(:tok_comma)
          end
        end
        
        expect(:tok_rparen)
        AST::RubyCall.new(module_path, method_name, arguments, previous_token.line)
      end

      def ruby_call_statement
        expect(:tok_ruby)
        ruby_call_expr = ruby_call()  # Używamy istniejącej metody ruby_call
        AST::RubyCallStmt.new(ruby_call_expr, previous_token.line)
      end

      def ruby_obj_call        
        expect(:tok_lparen)
        
        # first argument is ruby object
        object = expression
        
        expect(:tok_comma)
        
        # second argument is method name
        method_name_token = expect(:tok_string)
        method_name = method_name_token.lexeme
        
        # remaining arguments are call parameters
        arguments = []
        if match(:tok_comma)
          loop do
            arguments << expression
            break unless match(:tok_comma)
          end
        end
        
        expect(:tok_rparen)
        
        AST::RubyObjCall.new(object, method_name, arguments, previous_token.line)
      end
      
      def ruby_obj_call_statement
        expect(:tok_ruby_obj)
        ruby_obj_expr = ruby_obj_call()
        AST::RubyObjCallStmt.new(ruby_obj_expr, previous_token.line)
      end

      # <unary> ::= ('+'|'-'|'~') <unary> | <primary>
      # Handles unary operations like negation
      def unary
        if match(:tok_not) || match(:tok_minus) || match(:tok_plus)
          op = previous_token
          operand = unary
          return AST::UnOp.new(op, operand, op.line)
        end

        primary
      end

      # ::= <unary> ("^" <unary>)*
      def exponent
        expr = unary

        while match(:tok_caret)
          op = previous_token
          right = exponent
          expr = AST::BinOp.new(op, expr, right, op.line)
        end

        expr
      end

      # <modulo> ::= <exponent> ("%" <exponent>)*
      def modulo
        expr = exponent

        while match(:tok_mod)
          op = previous_token
          right = exponent
          expr = AST::BinOp.new(op, expr, right, op.line)
        end

        expr
      end

      # <multiplication> ::= <modulo> ( ('*'|'/') <modulo> )*
      # Handles multiplication and division with proper precedence
      def multiplication
        expr = modulo

        while match(:tok_star) || match(:tok_slash)
          op = previous_token
          right = modulo
          expr = AST::BinOp.new(op, expr, right, op.line)
        end

        expr
      end

      # <addition> ::= <multiplication> ( ('+'|'-') <multiplication> )*
      # Handles addition and subtraction with proper precedence
      def addition
        expr = multiplication

        while match(:tok_plus) || match(:tok_minus) || match(:tok_append) # <<
          op = previous_token
          right = multiplication
          expr = AST::BinOp.new(op, expr, right, op.line)
        end

        expr
      end

      # <comparsion> ::= <addition> ((">" | ">=" | "<" | "<="))*
      def comparison
        expr = addition
        while match(:tok_greater) || match(:tok_greateroreq) || match(:tok_smalleroreq) || match(:tok_smaller)
          op = previous_token
          right = addition
          expr = AST::BinOp.new(op, expr, right, op.line)
        end

        expr
      end

      # <equality> ::= <comparsion>  ( ("~=" | "==")) <comparsion>
      def equality
        expr = comparison
        while match(:tok_eq) || match(:tok_noteq)
          op = previous_token
          right = comparison
          expr = AST::BinOp.new(op, expr, right, op.line)
        end

        expr
      end

      # <logical_and> ::= <equality> ("and" <equality>)*
      def logical_and
        expr = equality
        while match(:tok_and)
          op = previous_token
          right = if next?(:tok_identifier) && peek_next && peek_next.token_type == :tok_assign
                    identifier = advance
                    expect(:tok_assign)
                    value = expression
                    AST::AssignmentExpr.new(AST::Identifier.new(identifier.lexeme, identifier.line), value,
                                            identifier.line)
                  else
                    equality
                  end
          expr = AST::LogicalOp.new(op, expr, right, op.line)
        end
        expr
      end

      # <logical_or> ::= <logical_and> ("or" <logical_and>)*
      def logical_or
        expr = logical_and
        while match(:tok_or)
          op = previous_token
          right = if next?(:tok_identifier) && peek_next && peek_next.token_type == :tok_assign
                    identifier = advance
                    expect(:tok_assign)
                    value = expression
                    AST::AssignmentExpr.new(AST::Identifier.new(identifier.lexeme, identifier.line), value,
                                            identifier.line)
                  else
                    logical_and
                  end
          expr = AST::LogicalOp.new(op, expr, right, op.line)
        end
        expr
      end

      def expression
        expr = logical_or
        postfix(expr)
      end

      # methods called on expresions, eg: "5".typ()
      def postfix(expr)
        loop do
          break unless match(:tok_dot)

          method_name = parse_method_name
          arguments = []
          if match(:tok_lparen)
            unless next?(:tok_rparen)
              loop do
                arguments << expression
                break unless match(:tok_comma)
              end
            end
            expect(:tok_rparen)
          end
          expr = AST::MethodCall.new(expr, method_name, arguments, previous_token.line)
        end
        expr
      end

      # <print_statement> :== "pokaz" <expression>
      def print_statement
        return unless match(:tok_print)

        value = expression
        AST::PrintStmt.new(value, previous_token.line)
      end

      # <println_statement> :== "pokazl" <expression>
      def println_statement
        return unless match(:tok_println)

        value = expression
        AST::PrintlnStmt.new(value, previous_token.line)
      end

      # <if_statement> ::= "jesli" <expression> "albojesli" <stmts>*? {<stmts> "albo" <stmts>}?
      def if_statement
        expect(:tok_if)
        test = expression

        if next?(:tok_then) # if ... then ... statement
          advance
          then_stmt = statement
          AST::OneLinerIfStmt.new(test, then_stmt, previous_token.line)
        else
          expect(:tok_lcurly) # {
          then_stmt = statements
          expect(:tok_rcurly) # }
          else_if_conditions = []

          while next?(:tok_elseif)
            advance
            else_if_test = expression
            expect(:tok_lcurly) # {
            else_if_stmt = statements
            expect(:tok_rcurly) # }
            else_if_conditions << [else_if_test, else_if_stmt]
          end

          if next?(:tok_else)
            advance # consume else
            expect(:tok_lcurly)
            else_stmts = statements
            expect(:tok_rcurly)
          else
            else_stmts = nil
          end

          AST::IfStmt.new(test, then_stmt, else_stmts, else_if_conditions, previous_token.line)
        end
      end

      def array_statement
        elements = []

        # Parse array elements

        # handle empty arrays
        if next?(:tok_rsquare)
          advance
          return AST::ArrayLiteral.new([], previous_token.line)
        end

        # iterate over array elements
        loop do
          elements << expression

          break unless match(:tok_comma)

          if next?(:tok_rsquare) # case: [1,2,]
            advance
            break
          end
        end

        expect(:tok_rsquare) # ]
        AST::ArrayLiteral.new(elements, previous_token.line)
      end

      def while_statement
        expect(:tok_while)
        test = expression
        expect(:tok_lcurly) # {
        body_statement = statements
        expect(:tok_rcurly) # }

        AST::WhileStmt.new(test, body_statement, previous_token.line)
      end

      # <for_statement> :== "dla" <identifier> "=" <start> ";" <end> (";" <increment>)? "{" <body_statement> "]"
      def for_statement
        expect(:tok_for)

        if match(:tok_let) # standard loop for ranges
          identifier = primary
          expect(:tok_assign)
          start_statement = expression
          expect(:tok_semicolon)
          end_statement = expression
          step_statement = nil
          step_statement = expression if match(:tok_semicolon)
          expect(:tok_lcurly)
          body_statement = statements
          expect(:tok_rcurly)

          AST::ForStmt.new(identifier, start_statement, end_statement, step_statement, body_statement,
                           previous_token.line)
        else # loops for collections
          element_identifier = AST::Identifier.new(expect(:tok_identifier).lexeme, previous_token.line)

          if match(:tok_comma) # for objects: dla klucz, wartosc w obj
            value_identifier = AST::Identifier.new(expect(:tok_identifier).lexeme, previous_token.line)
            expect(:tok_in)
            object = expression
            expect(:tok_lcurly)
            body_statement = statements
            expect(:tok_rcurly)

            AST::ForInObjectStmt.new(element_identifier, value_identifier, object, body_statement, previous_token.line)
          else # dla arrays: dla element w arr
            expect(:tok_in)
            collection = expression
            expect(:tok_lcurly)
            body_statement = statements
            expect(:tok_rcurly)

            AST::ForInArrayStmt.new(element_identifier, collection, body_statement, previous_token.line)
          end
        end
      end

      # <loop_statement> ::= "petla" "{" <statement>*? "}"
      def loop_statement
        advance
        expect(:tok_lcurly) # {
        body_statement = statements
        expect(:tok_rcurly) # }
        AST::LoopStmt.new(body_statement, previous_token.line)
      end

      # <func_decl> :== "funkcja" <name> "(" <params>? ")" "{" <body_stmts> "}"
      def func_decl
        expect(:tok_func)
        name = expect(:tok_identifier)
        expect(:tok_lparen) # (
        f_params = params
        expect(:tok_rparen) # )
        expect(:tok_lcurly) # {

        # if next token is "}", function body is empty
        body_statement = if next?(:tok_rcurly)
                           AST::Stmts.new([], previous_token.line) # empty statements list
                         else
                           statements
                         end

        expect(:tok_rcurly) # }

        AST::FuncDclr.new(name.lexeme, f_params, body_statement, previous_token.line)
      end

      # <class_definition> :== "klasa" <name> < <parent_class>? {}
      def class_definition
				is_abstract = match(:tok_abstract)
				
				expect(:tok_class)
				class_name = expect(:tok_identifier).lexeme
				
				# check if there's inheritance
				parent_class = nil
				if match(:tok_smaller)  # 
					parent_class = expect(:tok_identifier).lexeme
				end
				
				expect(:tok_lcurly)  # {

				# create empty statements object if class body is empty
				class_body = nil
				if next?(:tok_rcurly)
					# if class is empty, create empty statement list
					class_body = AST::Stmts.new([], previous_token.line)
				else
					@inside_class_body = true  # set flag for entering class body
					class_body = statements
					@inside_class_body = false  # reset flag after leaving class body
				end
				
				expect(:tok_rcurly)  # }
				
				AST::ClassDefinition.new(class_name, parent_class, class_body, previous_token.line, is_abstract)
			end

      # <exit_statement> ::= "wyjscie" "(" <expression>? ")"
      def exit_statement
        advance
        expect(:tok_lparen) # (
        message = expression unless next?(:tok_rparen)
        expect(:tok_rparen) # (

        AST::ExitStmt.new(message, previous_token.line)
      end

      # <exit_statement> ::= "wczytaj"  "(" <expression>? ")"
      def input_statement
        prompt = nil
        expect(:tok_lparen) # (
        prompt = expression unless next?(:tok_rparen)
        expect(:tok_rparen) # (
        Input.new(prompt, previous_token.line)
      end

      # <arguments> :== <expr> (',' <expr>)*
      def arguments
        f_args = []
        until next?(:tok_rparen)
          f_args << expression
          expect(:tok_comma) unless next?(:tok_rparen)
        end
        f_args
      end

      # <params> :== <identifier> (',' <identifier>)*
      def params
        f_params = []
        params_num = 0
        has_default = false
        has_rest = false
        
        until next?(:tok_rparen)
          params_num += 1
          AST::Utils.parse_error('Liczba parametrow w funkcji przekracza 255', previous_token.line) if params_num > 255
          
          # check if it's a 'rest' param
          rest = false
          if match(:tok_star)  # *
            rest = true
            has_rest = true
          end
          
          if has_rest && !rest
            Utils.parse_error("Parametr typu rest (*) musi być ostatnim parametrem", previous_token.line)
          end
          
          name = expect(:tok_identifier)

          default_value = nil
          if match(:tok_assign)  # =
            if rest
              Utils.parse_error("Parametr typu rest (*) nie może mieć wartości domyślnej", previous_token.line)
            end
            
            has_default = true
            default_value = expression
          elsif has_default && !rest
            # params with default values must be before rest param
            Utils.parse_error("Parametry bez wartosci domyslnych nie moga występowac po parametrach z wartosciami domyslnymi", previous_token.line)
          end
          
          f_params << AST::Param.new(name.lexeme, previous_token.line, default_value, rest)
          
          if rest && next?(:tok_comma)
            Utils.parse_error("Parametr typu rest (*) musi być ostatnim parametrem", previous_token.line)
          end
          
          expect(:tok_comma) unless next?(:tok_rparen)
        end
        
        f_params
      end

      # <return_stmt> :== "zwroc" <expression>
      def return_statement
        expect(:tok_return)
        value = expression
        AST::ReturnStatement.new(value, previous_token.line)
      end

      # <variable_statment> :== "niech" <expression> <assign> "=" <expression>
      def var_declaration_statement
        expect(:tok_let)
				
				# check if its a declaration of a static variable: niech NAZWA_KLASY.ZMIENNA_STATYCZNA = wartość
				if next?(:tok_identifier) && peek_next && peek_next.token_type == :tok_dot
					class_name = expect(:tok_identifier).lexeme
					expect(:tok_dot)
					
					if next?(:tok_identifier) && peek.lexeme.match?(/^[A-Z_]+$/)
						static_var_name = expect(:tok_identifier).lexeme
						expect(:tok_assign)
						value = expression
						
						return AST::StaticVariableDeclaration.new(class_name, static_var_name, value, previous_token.line)
					end
				end
				
        left = expression

        # check if not trying to assing to 'sam' (self)
        if left.is_a?(AST::SelfReference)
          Utils.parse_error("Nie można przypisać wartości do słowa kluczowego 'sam'", left.line)
        end
        
        # check if it's an instance variable (@)
        if left.is_a?(AST::InstanceVariable)
          expect(:tok_assign)
          right = expression
          return AST::InstanceVariableDeclaration.new(left.name, right, previous_token.line)
        end
        
        # for regular variables
        expect(:tok_assign)
        right = expression
        AST::VariableDeclaration.new(left, right, previous_token.line)
      end

      # <global_variable_statment> :== "globalna" "niech" <expression> <assign> "=" <expression>
      def global_var_declaration_statement
        expect(:tok_global)
        expect(:tok_let)
        left = expression
        expect(:tok_assign)
        right = expression
        AST::GlobalVariableDeclaration.new(left, right, previous_token.line)
      end

      # <import_statement> ::= "importuj" "(" <expression> ")"
      def import_file_statement
        advance
        expect(:tok_lparen)
        path = expect(:tok_string).lexeme
        expect(:tok_rparen)
        AST::ImportStmt.new(path, previous_token.line)
      end

      # <try_statement> ::= "proba" "{" <statements> "}" <catch_clause>* <finally_clause>?
      def try_statement
        expect(:tok_try)
        expect(:tok_lcurly)
        try_block = statements
        expect(:tok_rcurly)
        
        catch_blocks = []
        while next?(:tok_catch)
          catch_blocks << catch_clause
        end
        
        finally_block = finally_clause if next?(:tok_finally)
        
        AST::TryCatchStmt.new(try_block, catch_blocks, finally_block, previous_token.line)
      end

      # <catch_clause> ::= "zlap" "(" <identifier> (":" <identifier>)? ")" "{" <statements> "}"
      def catch_clause
        expect(:tok_catch)
        expect(:tok_lparen)
        exception_var = expect(:tok_identifier).lexeme
        
        # Opcjonalny typ wyjątku
        exception_type = nil
        if match(:tok_colon)
          exception_type = AST::Identifier.new(expect(:tok_identifier).lexeme, previous_token.line)
        end
        
        expect(:tok_rparen)
        expect(:tok_lcurly)
        body = statements
        expect(:tok_rcurly)
        
        AST::CatchBlock.new(exception_var, body, exception_type, previous_token.line)
      end

      # <finally_clause> ::= "wkoncu" "{" <statements> "}"
      def finally_clause
        expect(:tok_finally)
        expect(:tok_lcurly)
        body = statements
        expect(:tok_rcurly)
        
        body
      end

      # <throw_statement> ::= "rzuc" <expression>
      def throw_statement
        expect(:tok_throw)
        expr = expression()
        AST::ThrowStmt.new(expr, nil, previous_token.line)
      end

      def private_section
        advance
        AST::PrivateSection.new(previous_token.line)
      end

      def require_ruby_statement
        expect(:tok_require_ruby)
        expect(:tok_lparen)
        library_name = expect(:tok_string).lexeme
        expect(:tok_rparen)
        
        AST::RequireRubyStmt.new(library_name, previous_token.line)
      end

    def module_definition
      expect(:tok_module)
      module_name = expect(:tok_identifier).lexeme
      
      # parent_module to pełna ścieżka do tego modułu
      parent_module = @current_module_path.empty? ? nil : @current_module_path.join("::")
      
      expect(:tok_lcurly)
      
      # push current module to path
      @current_module_path.push(module_name)
      
      module_body = if next?(:tok_rcurly)
                      AST::Stmts.new([], previous_token.line)
                    else
                      statements
                    end
      
      # pop after parsing body
      @current_module_path.pop
      
      expect(:tok_rcurly)
      
      AST::ModuleDefinition.new(module_name, module_body, previous_token.line, parent_module)
    end

      # metoda pomocnicza do parsowania nazw metod - pozwala na niektóre keywords
      def parse_method_name
        # lista keywords które mogą być nazwami metod
        allowed_method_keywords = [:tok_class, :tok_null, :tok_true, :tok_false, :tok_for, :tok_in]
        
        if allowed_method_keywords.include?(peek.token_type)
          token = advance
          return token.lexeme
        else
          return expect(:tok_identifier).lexeme
        end
      end
    

    def include_module_statement
      expect(:tok_include)
      module_name = expect(:tok_identifier).lexeme
      AST::IncludeModule.new(module_name, previous_token.line)
    end

      def statement
        # predict next token
        token = peek.token_type
        if token == :tok_let
          var_declaration_statement
        elsif token == :tok_global
          global_var_declaration_statement
        elsif token == :tok_print
          print_statement
        elsif token == :tok_println
          println_statement
        elsif token == :tok_if
          if_statement
        elsif token == :tok_while
          while_statement
        elsif token == :tok_for
          for_statement
        elsif token == :tok_loop
          loop_statement
        elsif token == :tok_break
          advance
          AST::BreakLoop.new(previous_token.line)
        elsif token == :tok_continue
          advance
          AST::ContinueLoop.new(previous_token.line)
        elsif token == :tok_func
          func_decl
        elsif token == :tok_return
          return_statement
        elsif token == :tok_exit
          exit_statement
        elsif token == :tok_import
          import_file_statement
        elsif token == :tok_try
          try_statement
        elsif token == :tok_throw
          throw_statement
        elsif token == :tok_class
            class_definition
        elsif token == :tok_module
            module_definition
        elsif token == :tok_private
            private_section
        elsif token == :tok_require_ruby
             require_ruby_statement
				elsif token == :tok_static
					Utils.parse_error("Słowo kluczowe 'statyczny' może być używane tylko w ciele klasy", peek.line) unless @inside_class_body
					advance
					AST::StaticKeyword.new(previous_token.line)
				elsif token == :tok_abstract  
					class_definition
        elsif token == :tok_ruby
          ruby_call_statement
        elsif token == :tok_ruby_obj
          ruby_obj_call_statement
        elsif token == :tok_include
          include_module_statement
        else
          left = expression
          if match(:tok_assign)
            # check if not trying to assing to 'sam' (self)
            if left.is_a?(AST::SelfReference)
              Utils.parse_error("Nie można przypisać wartości do słowa kluczowego 'sam'", left.line)
            end

            right = expression
            AST::Assignment.new(left, right, previous_token.line)
          elsif match(:tok_pluseq) || match(:tok_minuseq) ||
                match(:tok_stareq) || match(:tok_slasheq)
            operator = previous_token
            right = expression
            AST::CompoundAssignment.new(left, operator, right, previous_token.line)
          elsif left.is_a?(AST::FuncCall)
            # handle function calls and array access statements
            AST::FuncCallStmt.new(left, previous_token.line)
          elsif left.is_a?(AST::ObjectOrArrayAccess)
            AST::ObjectOrArrayAccessStmt.new(left, previous_token.line)
          elsif left.is_a?(AST::MethodCall)
            AST::MethodCallStmt.new(left, previous_token.line)
          elsif left.is_a?(AST::Input)
            AST::InputStmt.new(left, previous_token.line)
          elsif left.is_a?(AST::Expr)
            AST::ExpressionStmt.new(left, previous_token.line)
          elsif left.is_a?(AST::InstanceVariable)
            right = expression
            return AST::InstanceVariableAssignment.new(left.name, right, previous_token.line)
          else
            AST::Utils.parse_error('Niespodziewane wyrazenie', previous_token.line)
          end
        end
      end

      def statements
        stmts = []
        stmts << statement while @current < @tokens.size && !next?(:tok_rcurly)
        AST::Stmts.new(stmts, previous_token ? previous_token.line : 0)
      end

      # <program> ::= <statements>*
      def program
        statements
      end

      # entry point for parsing, returns completed AST
      def parse!
        program
      end
    end
  end
end
