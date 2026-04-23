# frozen_string_literal: true

module AlexScript
  module AST
    # print value (pokaz ...)
    class PrintStmt < Stmt
      attr_reader :value, :ending, :line

      def initialize(value, line)
        validate_types([value], [Expr], 'expression')
        @value = value
        @line = line
      end

      def evaluate(interpreter, env)
        expression_type, expression_value = interpreter.interpret!(@value, env)
        formatted_value = interpreter.format_value(expression_type, expression_value)
        print("#{formatted_value} ")
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}PrintStatement(",
          @value.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # print value with new line (pokazl ...)
    class PrintlnStmt < Stmt
      attr_reader :value, :ending, :line

      def initialize(value, line)
        validate_types([value], [Expr], 'expression')
        @value = value
        @line = line
      end

      def evaluate(interpreter, env)
        expression_type, expression_value = interpreter.interpret!(@value, env)
        formatted_value = interpreter.format_value(expression_type, expression_value)

        # For special values (bool, null, module), use puts to avoid adding quotes
        # For other types, use p() which preserves string quotes
        if expression_type == :type_bool || expression_type == :type_null || expression_type == :type_module
          puts formatted_value
        else
          p(formatted_value)
        end
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}PrintLineStatement(",
          @value.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # wyjscie()
    class ExitStmt < Stmt
      attr_reader :code, :line

      def initialize(code, line)
        validate_types([code], [Int]) unless code.nil?
        @code = code
        @line = line
      end

      def evaluate(_interpreter, _env)
        if @code
          exit(@code.value)
        else
          exit
        end
      end

      def pretty_print(level = 0)
        code = @code.nil? ? '' : @code.pretty_print(level + 1)

        [
          "#{indent(level)}ExitStatement(",
          code,
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # eg niech x = wczytaj(...)
    class Input < Expr
      attr_reader :prompt, :line

      def initialize(prompt, line)
        validate_types([prompt], [Expr], 'prompt') unless prompt.nil?
        @prompt = prompt
        @line = line
      end

      def evaluate(interpreter, env)
        if @prompt
          prompt_type, prompt_value = interpreter.interpret!(@prompt, env)
          puts(prompt_value)
        end

        input = STDIN.gets
        input = input.chomp if input

        [:type_string, input]
      end

      def pretty_print(level = 0)
        prompt = @prompt.nil? ? '' : @prompt.pretty_print(level + 1)

        [
          "#{indent(level)}InputStatement(",
          prompt,
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # wczytaj() but only as a stmt
    class InputStmt < Stmt
      attr_reader :expression, :line

      def initialize(expression, line)
        validate_types([expression], [Input])
        @expression = expression
        @line = line
      end

      def evaluate(interpreter, env)
        interpreter.interpret!(@expression, env)
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}InputStmt(",
          @expression.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # eg importuj(path/to/file)
    class ImportStmt < Stmt
      attr_reader :file_path, :line

      def initialize(file_path, line)
        validate_types([file_path], [String])
        @file_path = file_path
        @line = line
      end

      def evaluate(interpreter, env)
        display_path = interpreter.import_manager.canonical_display_name(@file_path)
        Utils::CallStackTracker.push(:import, display_path, interpreter.current_file, @line)
        begin
          imported_env = interpreter.import_manager.import_file(@file_path, interpreter.current_file, env)
          env.merge(imported_env) # merge imported env with parent env (main file which imports file)
        rescue Utils::AlexScriptError
          raise  # let the original error through — class, line and captured stack stay intact
        rescue StandardError => e
          Utils.runtime_error("Blad importu: #{e.message}", @line)
        ensure
          Utils::CallStackTracker.pop
        end
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}ImportStatement(",
          "#{indent(level + 1)}path: #{@file_path}",
          "#{indent(level)})"
        ].join("\n")
      end
    end
  end
end