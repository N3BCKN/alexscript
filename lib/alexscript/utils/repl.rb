# frozen_string_literal: true

require 'readline'

module AlexScript
  module Utils
    class Repl
      CURRENT_YEAR = Time.now.year

      # Statements that don't produce meaningful return values.
      # For these, we suppress the "=> nic" output.
      SILENT_NODES = [
        AST::PrintStmt, AST::PrintlnStmt, AST::WhileStmt, AST::LoopStmt,
        AST::ForStmt, AST::ForInArrayStmt, AST::ForInObjectStmt,
        AST::IfStmt, AST::OneLinerIfStmt, AST::ImportStmt,
        AST::ClassDefinition, AST::ModuleDefinition, AST::IncludeModule
      ].freeze

      def initialize
        @interpreter = Core::Interpreter.new
        @env = Core::Environment.new
        @line_no = 0
        @last_value = nil  # stores last result, accessible as _
        @should_exit = false

        # Register _ as a variable in the environment
        @env.set_local_var('_', NULL_VALUE, :type_null)

        display_banner
        run
      end

      def run
        loop do
          input = read_multiline_input
          break if input.nil? # Ctrl+D

          next if input.strip.empty?

          # handle REPL commands (not AS code)
          if handle_repl_command(input.strip)
            break if @should_exit
            next
          end

          execute(input)
        end
      end

      private

      def display_banner
        puts "AlexScript REPL #{VERSION} (2024-#{CURRENT_YEAR})"
        puts "Wpisz 'pomoc' aby zobaczyć dostępne komendy, 'koniec' aby wyjść."
        puts '─' * 55
      end

      # Handles special REPL commands. Returns true if input was a command.
      def handle_repl_command(input)
        case input
        when 'koniec', 'wyjscie', 'wyjscie()'
          puts "Do zobaczenia!"
          @should_exit = true
          true
        when 'pomoc'
          display_help
          true
        when 'wyczysc'
          print "\e[2J\e[H"  # ANSI clear screen
          true
        when 'env'
          display_environment
          true
        when 'reset'
          @env = Core::Environment.new
          @env.set_local_var('_', NULL_VALUE, :type_null)
          @line_no = 0
          puts "  Środowisko zresetowane."
          true
        else
          false
        end
      end

      def execute(input)
        begin
          lexer = Core::Lexer.new(input)
          tokens = lexer.tokenize!

          parser = Core::Parser.new(tokens)
          ast = parser.parse!

          # Unwrap Stmts to capture the return value of the last statement.
          # interpret!(Stmts) iterates with `while` and drops all return values.
          # We need the value of the last statement for "=> X" display.
          if ast.is_a?(AST::Stmts) && !ast.stmts.empty?
            # Execute all statements except the last
            ast.stmts[0...-1].each do |stmt|
              @interpreter.interpret!(stmt, @env)
            end

            last_stmt = ast.stmts.last
            result = @interpreter.interpret!(last_stmt, @env)

            # Determine if we should display the result
            display_result(result, last_stmt)
          else
            result = @interpreter.interpret!(ast, @env)
            display_result(result, ast)
          end
        rescue Utils::AlexScriptError => e
          puts "\e[31m#{e.alexscript_class_name}\e[0m: #{e.message}"
        rescue StandardError => e
          # Ruby-native exceptions — translate to AlexScript exception for consistency
          alex_exception = Utils::ExceptionsTranslator.translate(e)
          puts "\e[31m#{alex_exception.alexscript_class_name}\e[0m: #{alex_exception.message}"
        end
      end

      def display_result(result, node)
        # Don't display for explicitly silent statements (print, loops, etc.)
        return if silent_node?(node)

        # For variable declarations (niech x = 5), the interpreter returns
        # a hash from set_local_var, not a [type, value] pair.
        # Extract the declared value from env to display it.
        if node.is_a?(AST::VariableDeclaration) || node.is_a?(AST::GlobalVariableDeclaration)
          var_name = node.left.name
          var = @env.get_var(var_name)
          if var
            update_last_and_display(var[:type], var[:value])
          end
          return
        end

        # For assignments (x = 5), fetch updated value from env
        if node.is_a?(AST::Assignment) || node.is_a?(AST::CompoundAssignment)
          var_name = node.left.name rescue nil
          if var_name
            var = @env.get_var(var_name)
            if var
              update_last_and_display(var[:type], var[:value])
            end
          end
          return
        end

        # For function declarations, just confirm
        if node.is_a?(AST::FuncDclr)
          puts "=> \e[35m<funkcja #{node.name}>\e[0m"
          return
        end

        # Don't display if result is nil (some nodes return nil from interpret!)
        return unless result.is_a?(Array) && result.size == 2

        type, value = result
        update_last_and_display(type, value)
      end

      def update_last_and_display(type, value)
        @last_value = [type, value]
        # Update _ directly to ensure both type and value are set
        var = @env.get_var('_')
        if var
          var[:value] = value
          var[:type] = type
        end
        formatted = format_repl_value(type, value)
        puts "=> #{formatted}"
      end

      def silent_node?(node)
        SILENT_NODES.any? { |klass| node.is_a?(klass) }
      end

      # ── Value formatting ─────────────────────────────────────────────

      def format_repl_value(type, value)
        case type
        when :type_int
          "\e[36m#{value}\e[0m"
        when :type_float
          "\e[36m#{value}\e[0m"
        when :type_string
          "\e[32m\"#{value}\"\e[0m"
        when :type_bool
          bool_str = value == BOOL_TRUE ? 'prawda' : 'falsz'
          "\e[33m#{bool_str}\e[0m"
        when :type_null
          "\e[90mnic\e[0m"
        when :type_array
          format_repl_array(value)
        when :type_object
          format_repl_object(value)
        when :type_instance
          class_name = value[:class_name] rescue '?'
          "\e[35m#<#{class_name}:0x#{value.object_id.to_s(16)}>\e[0m"
        when :type_function
          "\e[35m<funkcja>\e[0m"
        when :type_module
          # dump the whole global scope. show a compact, Ruby-ish summary.
          name = value.is_a?(Hash) ? (value[:name] || 'UnnamedModule') : value.to_s
          "\e[35mmodul #{name}\e[0m"
        else
          value.inspect
        end
      end

      def format_repl_array(arr)
        return "\e[90m[]\e[0m" unless arr.is_a?(Array)

        if arr.size > 20
          elements = arr.first(20).map { |el| format_repl_element(el) }
          "[#{elements.join(', ')}, \e[90m... (#{arr.size} elementów)\e[0m]"
        else
          elements = arr.map { |el| format_repl_element(el) }
          "[#{elements.join(', ')}]"
        end
      end

      def format_repl_element(el)
        if el.is_a?(Hash) && el[:type]
          format_repl_value(el[:type], el[:value])
        else
          el.inspect
        end
      end

      def format_repl_object(obj)
        return "\e[90m{}\e[0m" unless obj.is_a?(Hash)

        if obj.size > 10
          pairs = obj.first(10).map { |k, v| format_repl_pair(k, v) }
          "{#{pairs.join(', ')}, \e[90m... (#{obj.size} kluczy)\e[0m}"
        else
          pairs = obj.map { |k, v| format_repl_pair(k, v) }
          "{#{pairs.join(', ')}}"
        end
      end

      def format_repl_pair(key, val)
        if val.is_a?(Hash) && val[:type]
          "\"#{key}\": #{format_repl_value(val[:type], val[:value])}"
        else
          "\"#{key}\": #{val.inspect}"
        end
      end

      # ── Prompt ─────────────────────────────────────────────────────────

      def main_prompt
        @line_no += 1
        "as:#{@line_no.to_s.rjust(3, '0')}> "
      end

      def cont_prompt
        "#{' ' * 3}..  "
      end

      # ── Multiline input ────────────────────────────────────────────────

      def read_multiline_input
        input_lines = []
        brace_count = 0
        prompt = main_prompt

        loop do
          line = Readline.readline(prompt, true)

          # Ctrl+D
          return nil if line.nil?

          # Remove duplicate history entries
          if Readline::HISTORY.length > 1 &&
             Readline::HISTORY[-1] == Readline::HISTORY[-2]
            Readline::HISTORY.pop
          end

          # Skip empty lines in single-line mode
          if line.strip.empty? && brace_count == 0
            Readline::HISTORY.pop if Readline::HISTORY.length > 0
            return ''
          end

          brace_count += line.count('{')
          brace_count -= line.count('}')

          input_lines << line

          if brace_count <= 0 && !input_lines.empty?
            break
          else
            prompt = cont_prompt
          end
        rescue Interrupt
          # Ctrl+C — cancel current input, start fresh
          puts ""
          return ''
        rescue StandardError => e
          puts "\e[31mBłąd wczytywania\e[0m: #{e.message}"
          return ''
        end

        input_lines.join("\n")
      end

      # ── Help ─────────────────────────────────────────────────────────

      def display_help
        puts <<~HELP

          \e[1mKomendy REPL:\e[0m
            koniec            Zakończ REPL
            pomoc             Pokaż tę pomoc
            wyczysc           Wyczyść ekran
            env               Pokaż wszystkie zmienne w środowisku
            reset             Zresetuj środowisko (wyczyść zmienne)

          \e[1mSkróty:\e[0m
            _                 Ostatnia zwrócona wartość
            Ctrl+C            Anuluj bieżące wejście
            Ctrl+D            Zakończ REPL

          Wpisz dowolne wyrażenie AlexScript, aby je wykonać.
          Wynik jest automatycznie wyświetlany jako => wartość.

        HELP
      end

      # ── Environment display ────────────────────────────────────────────

      def display_environment
        vars = @env.variables
        if vars.empty?
          puts "  (brak zmiennych)"
          return
        end

        puts "  \e[1m[Zmienne]\e[0m"
        vars.each do |name, info|
          next if name == '_'  # skip internal _ variable
          formatted = format_repl_value(info[:type], info[:value])
          const_marker = info[:constant] ? " \e[90m(stała)\e[0m" : ""
          puts "    #{name} = #{formatted}#{const_marker}"
        end

        funcs = @env.functions
        unless funcs.empty?
          puts "  \e[1m[Funkcje]\e[0m"
          funcs.each do |name, _|
            puts "    #{name}()"
          end
        end

        classes = @env.classes
        # Filter out built-in exception classes
        user_classes = classes.reject { |name, cls| cls[:is_exception] }
        unless user_classes.empty?
          puts "  \e[1m[Klasy]\e[0m"
          user_classes.each do |name, _|
            puts "    #{name}"
          end
        end
      end
    end
  end
end