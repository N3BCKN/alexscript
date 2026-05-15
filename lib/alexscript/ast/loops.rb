# frozen_string_literal: true

module AlexScript
  module AST
    # eg petla {...}
    class LoopStmt < Stmt
      attr_reader :body_statement, :line

      def initialize(body_statement, line)
        validate_types([body_statement], [Stmts])
        @body_statement = body_statement
        @line = line
      end

      def evaluate(interpreter, env)
        loop_env = env.new_env
        while true
          # Execute body in the loop's environment
          begin
            interpreter.interpret!(@body_statement, loop_env)
          rescue Utils::ContinueException
            next
          rescue Utils::BreakException
            break
          end
        end
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}Loop(",
          @body_statement.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # eg dla niech x = 0; 10; 1 {...}
    class ForStmt < Stmt
      attr_accessor :identifier, :start_statement, :end_statement, :step_statement, :body_statement
      attr_reader :line

      def initialize(identifier, start_statement, end_statement, step_statement, body_statement, line)
        validate_types([identifier], [Identifier])
        validate_types([start_statement, end_statement], [Expr])
        validate_types([step_statement], [Expr]) unless step_statement.nil?
        validate_types([body_statement], [Stmts])
        @identifier = identifier
        @start_statement = start_statement
        @end_statement = end_statement
        @step_statement = step_statement
        @body_statement = body_statement
        @line = line
      end

      def evaluate(interpreter, env)
        var_name = @identifier.name
        index_type, index_value = interpreter.interpret!(@start_statement, env)
        end_type, end_value = interpreter.interpret!(@end_statement, env)

        # Create a new environment for the while loop scope
        loop_env = env.new_env

        # Resolve step once. Default is +1 going up, -1 going down (matches
        # original behaviour where each branch had its own default).
        if @step_statement
          _step_type, step = interpreter.interpret!(@step_statement, env)
        else
          step = index_value < end_value ? 1 : -1
        end

        if step > 0
          while index_value < end_value
            begin
              loop_env.set_local_var(var_name, index_value, :type_int)
              interpreter.interpret!(@body_statement, loop_env)
            rescue Utils::ContinueException
            rescue Utils::BreakException
              break
            end
            index_value += step
          end
        else
          while index_value > end_value
            begin
              loop_env.set_local_var(var_name, index_value, :type_int)
              interpreter.interpret!(@body_statement, loop_env)
            rescue Utils::ContinueException
            rescue Utils::BreakException
              break
            end
            index_value += step
          end
        end
      end

      def pretty_print(level = 0)
        step_statement = @step_statement.pretty_print(level + 1) unless @step_statement.nil?

        [
          "#{indent(level)}ForLoop(",
          @identifier.pretty_print(level + 1),
          @start_statement.pretty_print(level + 1),
          @end_statement.pretty_print(level + 1),
          step_statement,
          "#{@body_statement.pretty_print(level + 1)}",
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # Example: dopoki x <= n {<body_statement>*}
    class WhileStmt < Stmt
      attr_reader :test, :body_statement, :line

      def initialize(test, body_statement, line)
        validate_types([test], [Expr])
        validate_types([body_statement], [Stmts])
        @test = test
        @body_statement = body_statement
        @line = line
      end

      def evaluate(interpreter, env)
        # Create a new environment for the while loop scope
        loop_env = env.new_env

        while true
          # Evaluate test condition in the parent environment
          test_type, test_value = interpreter.interpret!(@test, env)

          # Validate the test condition type
          Utils.runtime_error('Test while nie jest wyrazeniem boolowskim', @line) if test_type != :type_bool

          # Exit loop if condition is false
          break unless test_value == Utils::BOOL_TRUE

          # Execute body in the loop's environment
          begin
            interpreter.interpret!(@body_statement, loop_env)
          rescue Utils::ContinueException
            next
          rescue Utils::BreakException
            break
          end
        end
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}While(",
          @test.pretty_print(level + 1),
          @body_statement.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # dla klucz, wartosc w obiekt {...}
    class ForInObjectStmt < Stmt
      attr_reader :key_identifier, :value_identifier, :object, :body_statement, :line

      def initialize(key_identifier, value_identifier, object, body_statement, line)
        validate_types([key_identifier], [Identifier], 'key identifier')
        validate_types([value_identifier], [Identifier], 'value identifier') unless value_identifier.nil?
        validate_types([object], [Expr], 'object')
        validate_types([body_statement], [Stmts], 'body')
        @key_identifier = key_identifier
        @value_identifier = value_identifier
        @object = object
        @body_statement = body_statement
        @line = line
      end

      def evaluate(interpreter, env)
        object_type, object_value = interpreter.interpret!(@object, env)
        Utils.runtime_error('Moze iterowac tylko po obiektach', @line) unless object_type == :type_object

        loop_env = env.new_env

        object_value.each do |key, value|
          # always set key (it's required)
          loop_env.set_var(@key_identifier.name, key, :type_string)

          # setting value is optional
          loop_env.set_var(@value_identifier.name, value[:value], value[:type]) if @value_identifier

          interpreter.interpret!(@body_statement, loop_env)
        rescue Utils::BreakException
          break
        rescue Utils::ContinueException
          next
        end
      end

      def pretty_print(level = 0)
        value_identifier = @value_identifier.nil? ? nil : @value_identifier.pretty_print(level + 1)

        [
          "#{indent(level)}ForInObjectLoop(",
          @key_identifier.pretty_print(level + 1),
          value_identifier,
          @object.pretty_print(level + 1),
          "#{@body_statement.pretty_print(level + 1)}",
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # dla indeks w tablica {...}
    class ForInArrayStmt < Stmt
      attr_reader :element_identifier, :array, :body_statement, :line

      def initialize(element_identifier, array, body_statement, line)
        validate_types([element_identifier], [Identifier], 'element identifier')
        validate_types([array], [Expr], 'array')
        validate_types([body_statement], [Stmts], 'body')
        @element_identifier = element_identifier
        @array = array
        @body_statement = body_statement
        @line = line
      end

      def evaluate(interpreter, env)
        array_type, array_value = interpreter.interpret!(@array, env)
        Utils.runtime_error('Moze iterowac tylko po tablicach', @line) unless array_type == :type_array

        loop_env = env.new_env

        array_value.each do |element|
          # set values in env
          if element.is_a?(Hash)
            loop_env.set_var(@element_identifier.name, element[:value], element[:type])
          else
            loop_env.set_var(@element_identifier.name, element, interpreter.get_type(element)) # TODO: FIX THIS MISSING get_type METHOD ASAP
          end

          interpreter.interpret!(@body_statement, loop_env)
        rescue Utils::BreakException
          break
        rescue Utils::ContinueException
          next
        end
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}ForInArrayLoop(",
          @element_identifier.pretty_print(level + 1),
          @array.pretty_print(level + 1),
          "#{@body_statement.pretty_print(level + 1)}",
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # zakoncz (break loop)
    class BreakLoop < Stmt
      attr_reader :line

      def initialize(line)
        @line = line
      end

      def evaluate(_interpreter, _env)
        raise Utils::BreakException.new
      end

      def pretty_print(level = 0)
        "#{indent(level)}BreakLoop()"
      end
    end

    # nastepny (next/continue loop)
    class ContinueLoop < Stmt
      attr_reader :line

      def initialize(line)
        @line = line
      end

      def evaluate(_interpreter, _env)
        raise Utils::ContinueException.new
      end

      def pretty_print(level = 0)
        "#{indent(level)}ContinueLoop()"
      end
    end
  end
end