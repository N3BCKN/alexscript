# frozen_string_literal: true

require 'readline'
require 'set'

module AlexScript
  module Utils
    # ==========================================================================
    # DEBUGGER — Interactive debugger for AlexScript
    # ==========================================================================
    #
    # Activated by placing debug() in AlexScript source code.
    # Provides step-by-step execution, breakpoints, variable inspection,
    # expression evaluation, watch expressions, and conditional breakpoints.
    #
    # Architecture:
    #   - Singleton with class-level state (like CallStackTracker)
    #   - State machine with modes: :inactive, :step, :next, :step_out, :continue
    #   - Thin hook in interpreter's interpret! method
    #   - REPL loop uses Readline for interactive commands
    #
    # Performance:
    #   - When inactive: cost is one `if false` per AST node (branch prediction)
    #   - When active but continuing: one hash lookup per line change
    #
    class Debugger
      # ── State ──────────────────────────────────────────────────────────────
      @mode = :inactive        # :inactive | :step | :next | :step_out | :continue
      @breakpoints = {}        # { file_path => Set<line_number> }
      @next_id = 1             # auto-increment ID for breakpoint listing

      # For :next and :step_out — the call depth at which we should pause
      @target_depth = nil

      # Deduplication — avoid triggering multiple times on same source line
      @last_file = nil
      @last_line = nil

      # Reference to interpreter instance (needed for expression evaluation)
      @interpreter = nil

      # Breakpoint metadata for listing/removing
      # { id => { file:, line:, condition: nil|String } }
      @breakpoint_list = {}

      # Watch expressions — auto-evaluated at each pause
      # { id => String }
      @watch_list = {}
      @next_watch_id = 1

      PROMPT = 'debug> '

      class << self
        attr_reader :mode

        # ── Query methods ──────────────────────────────────────────────────

        # Returns true if debugger is doing any stepping (not inactive).
        # This is the hot-path check in interpret! — must be fast.
        def stepping?
          @mode != :inactive
        end

        # ── Activation (called from AST::DebugBreak handling) ────────────

        # Called when interpreter encounters a debug() statement.
        # Activates the debugger and drops into the REPL.
        def activate!(node, env, interpreter)
          @interpreter = interpreter
          file = ContextTracker.current_file
          line = node.line

          puts "\n\e[31m⏺\e[0m  debug() w #{format_location(file, line)}"
          display_source_context(file, line)
          display_watches(env)

          # After debug(), we pause on the very next line
          @mode = :step
          @last_file = file
          @last_line = line

          run_repl(env, file, line)
        end

        # ── Hook (called from interpret! on every node with a line) ───────

        # Called on every AST node when debugger is stepping.
        # Decides whether to pause based on current mode.
        def check(node, env, interpreter)
          return unless node.respond_to?(:line) && node.line
          @interpreter = interpreter

          file = ContextTracker.current_file
          line = node.line

          # Deduplicate: don't trigger again on the same source line
          # unless we've gone through a different line and come back (e.g. loop)
          return if file == @last_file && line == @last_line

          should_pause = case @mode
                         when :step
                           true
                         when :next
                           CallStackTracker.depth <= @target_depth
                         when :step_out
                           CallStackTracker.depth < @target_depth
                         when :continue
                           breakpoint_hit?(file, line, env)
                         else
                           false
                         end

          return unless should_pause

          @last_file = file
          @last_line = line

          if @mode == :continue && breakpoint_at?(file, line)
            bp_info = find_breakpoint_info(file, line)
            if bp_info && bp_info[:condition]
              puts "\n\e[33m⏸\e[0m  Breakpoint warunkowy w #{format_location(file, line)} \e[90m(#{bp_info[:condition]})\e[0m"
            else
              puts "\n\e[33m⏸\e[0m  Breakpoint w #{format_location(file, line)}"
            end
          else
            puts "\n\e[33m⏸\e[0m  #{format_location(file, line)}"
          end

          display_source_context(file, line)
          display_watches(env)
          run_repl(env, file, line)
        end

        # ── Reset ─────────────────────────────────────────────────────────

        def reset!
          @mode = :inactive
          @breakpoints.clear
          @breakpoint_list.clear
          @next_id = 1
          @target_depth = nil
          @last_file = nil
          @last_line = nil
          @interpreter = nil
          @watch_list.clear
          @next_watch_id = 1
        end

        private

        # ── REPL ──────────────────────────────────────────────────────────

        def run_repl(env, file, line)
          loop do
            input = Readline.readline(PROMPT, true)

            # Handle Ctrl+D — treat as 'dalej'
            if input.nil?
              puts ""
              handle_continue
              break
            end

            input = input.strip
            next if input.empty?

            # Remove duplicate consecutive history entries
            if Readline::HISTORY.length > 1 &&
               Readline::HISTORY[-1] == Readline::HISTORY[-2]
              Readline::HISTORY.pop
            end

            should_break = execute_command(input, env, file, line)
            break if should_break
          end
        end

        # Executes a debugger command. Returns true if REPL should exit
        # (i.e., execution should resume).
        def execute_command(input, env, file, line)
          parts = input.split(/\s+/, 2)
          cmd = parts[0]
          args = parts[1]

          case cmd
          # ── Execution control ──
          when 'dalej', 'd'
            handle_continue
            true
          when 'krok', 'k'
            handle_step
            true
          when 'nastepna', 'n'
            handle_next
            true
          when 'wyjdz', 'w'
            handle_step_out
            true

          # ── Inspection ──
          when 'zmienne', 'z'
            if args && args.strip == 'wszystkie'
              display_all_scopes(env)
            else
              display_variables(env)
            end
            false
          when 'stos', 's'
            display_call_stack
            false
          when 'kod'
            ctx = args ? args.to_i : 5
            ctx = 5 if ctx <= 0
            display_source_context(file, line, context: ctx)
            false
          when 'p'
            if args && !args.empty?
              evaluate_expression(args, env)
            else
              puts "  Użycie: p <wyrażenie>"
            end
            false

          # ── Breakpoints ──
          when 'ustaw'
            if args && !args.empty?
              add_breakpoint(args, file)
            else
              puts "  Użycie: ustaw <linia> [jezeli <warunek>]"
            end
            false
          when 'usun'
            if args && !args.empty?
              remove_breakpoint(args)
            else
              puts "  Użycie: usun <numer>"
            end
            false
          when 'punkty'
            list_breakpoints
            false

          # ── Watch expressions ──
          when 'obserwuj'
            if args && !args.empty?
              add_watch(args)
            else
              list_watches
            end
            false
          when 'usun_obserwuj'
            if args && !args.empty?
              remove_watch(args)
            else
              puts "  Użycie: usun_obserwuj <numer>"
            end
            false

          # ── Exit debugger ──
          when 'koniec'
            handle_quit
            true

          # ── Help ──
          when 'pomoc', 'h', '?'
            display_help
            false

          else
            # Fallback: treat unrecognized input as an AlexScript expression.
            # This allows typing `x + y` directly instead of `p x + y`.
            evaluate_expression(input, env)
            false
          end
        end

        # ── Command handlers ─────────────────────────────────────────────

        def handle_continue
          @mode = :continue
          @last_file = nil
          @last_line = nil
        end

        def handle_step
          @mode = :step
          @last_file = nil
          @last_line = nil
        end

        def handle_next
          @mode = :next
          @target_depth = CallStackTracker.depth
          @last_file = nil
          @last_line = nil
        end

        def handle_step_out
          @mode = :step_out
          @target_depth = CallStackTracker.depth
          @last_file = nil
          @last_line = nil
        end

        def handle_quit
          @mode = :inactive
          @last_file = nil
          @last_line = nil
          puts "  Debugger zakończony."
        end

        # ── Variable inspection ──────────────────────────────────────────

        def display_variables(env)
          has_output = false

          # 1. Local variables from current scope
          locals = collect_local_variables(env)
          unless locals.empty?
            puts "  \e[1m[Zmienne lokalne]\e[0m"
            locals.each do |name, info|
              puts "    #{name} = #{format_debug_value(info[:type], info[:value])}"
            end
            has_output = true
          end

          # 2. Instance variables (if in instance method context)
          instance = env.get_instance
          if instance && instance[:instance_vars] && !instance[:instance_vars].empty?
            puts "  \e[1m[Zmienne instancji]\e[0m  (#{instance[:class_name]})"
            instance[:instance_vars].each do |name, var_data|
              if var_data.is_a?(Array) && var_data.size == 2 && var_data[0].is_a?(Symbol)
                puts "    @#{name} = #{format_debug_value(var_data[0], var_data[1])}"
              end
            end
            has_output = true
          end

          puts "  (brak zmiennych w bieżącym zakresie)" unless has_output
        end

        # Displays variables from ALL scopes — walks the parent chain.
        # Each scope is shown with its depth level.
        def display_all_scopes(env)
          has_output = false
          current = env
          depth = 0

          while current
            vars = collect_local_variables(current)
            unless vars.empty?
              label = case depth
                      when 0 then "Bieżący zakres"
                      else "Zakres nadrzędny (#{depth})"
                      end
              puts "  \e[1m[#{label}]\e[0m"
              vars.each do |name, info|
                puts "    #{name} = #{format_debug_value(info[:type], info[:value])}"
              end
              has_output = true
            end

            depth += 1
            current = current.parent
          end

          # Instance variables — always show at the end if present
          instance = env.get_instance
          if instance && instance[:instance_vars] && !instance[:instance_vars].empty?
            puts "  \e[1m[Zmienne instancji]\e[0m  (#{instance[:class_name]})"
            instance[:instance_vars].each do |name, var_data|
              if var_data.is_a?(Array) && var_data.size == 2 && var_data[0].is_a?(Symbol)
                puts "    @#{name} = #{format_debug_value(var_data[0], var_data[1])}"
              end
            end
            has_output = true
          end

          puts "  (brak zmiennych we wszystkich zakresach)" unless has_output
        end

        # Collects local variables from a specific scope (not parent scopes)
        def collect_local_variables(env)
          result = {}
          env.variables.each do |name, info|
            next if name.start_with?('__')  # skip internal variables
            result[name] = info
          end
          result
        end

        # ── Call stack display ───────────────────────────────────────────

        def display_call_stack
          stack = CallStackTracker.current_stack
          if stack.empty?
            puts "  (stos wywołań jest pusty — jesteś w zakresie globalnym)"
          else
            puts "  \e[1m[Stos wywołań]\e[0m"
            formatted = CallStackTracker.format_stack(stack)
            formatted.each { |frame| puts frame }
          end
        end

        # ── Source code display ──────────────────────────────────────────

        def display_source_context(file, line, context: 3)
          output = SourceCache.display(file, line, context: context)
          puts output
        end

        # ── Expression evaluation ────────────────────────────────────────

        def evaluate_expression(expr_str, env)
          begin
            lexer = Core::Lexer.new(expr_str)
            tokens = lexer.tokenize!
            parser = Core::Parser.new(tokens)
            ast = parser.parse!

            # parse! returns AST::Stmts which drops return values in its
            # while loop. For the `p` command we need the actual value.
            # Unwrap: if there's exactly one statement, interpret it directly.
            target = ast
            if ast.is_a?(AST::Stmts) && ast.stmts.size == 1
              target = ast.stmts[0]
            end

            # Temporarily disable stepping to avoid triggering debugger
            # inside the evaluation itself
            saved_mode = @mode
            @mode = :inactive
            begin
              result = @interpreter.interpret!(target, env)

              if result.is_a?(Array) && result.size == 2
                formatted = format_debug_value(result[0], result[1])
                puts "  => #{formatted}"
              else
                puts "  => \e[90mnic\e[0m"
              end
            ensure
              @mode = saved_mode
            end
          rescue StandardError => e
            puts "  \e[31mBłąd\e[0m: #{e.message}"
          end
        end

        # Silently evaluates an expression. Returns [type, value] or nil on error.
        # Used by conditional breakpoints and watch expressions.
        def silent_evaluate(expr_str, env)
          begin
            lexer = Core::Lexer.new(expr_str)
            tokens = lexer.tokenize!
            parser = Core::Parser.new(tokens)
            ast = parser.parse!

            target = ast
            if ast.is_a?(AST::Stmts) && ast.stmts.size == 1
              target = ast.stmts[0]
            end

            saved_mode = @mode
            @mode = :inactive
            begin
              @interpreter.interpret!(target, env)
            ensure
              @mode = saved_mode
            end
          rescue StandardError
            nil
          end
        end

        # ── Breakpoint management ────────────────────────────────────────

        def add_breakpoint(args, current_file)
          # Parse conditional breakpoints:
          #   ustaw 10 jezeli x > 5
          #   ustaw plik.as:10 jezeli x > 5
          #   ustaw 10
          #   ustaw plik.as:10
          condition = nil
          location_part = args

          # Check for 'jezeli' keyword to split condition
          jezeli_idx = args.index(' jezeli ')
          if jezeli_idx
            location_part = args[0...jezeli_idx].strip
            condition = args[(jezeli_idx + 8)..-1].strip  # 8 = ' jezeli '.length
            if condition.empty?
              puts "  Błąd: Brak warunku po 'jezeli'."
              return
            end
          end

          # Parse location (file:line or just line)
          if location_part.include?(':')
            parts = location_part.split(':', 2)
            bp_file = parts[0].strip
            bp_line = parts[1].strip.to_i
          else
            bp_file = current_file
            bp_line = location_part.strip.to_i
          end

          if bp_line <= 0
            puts "  Błąd: Nieprawidłowy numer linii."
            return
          end

          # Validate condition syntax (try to parse it)
          if condition
            begin
              lexer = Core::Lexer.new(condition)
              lexer.tokenize!
            rescue StandardError => e
              puts "  \e[31mBłąd składni warunku\e[0m: #{e.message}"
              return
            end
          end

          @breakpoints[bp_file] ||= Set.new
          @breakpoints[bp_file].add(bp_line)

          id = @next_id
          @next_id += 1
          @breakpoint_list[id] = { file: bp_file, line: bp_line, condition: condition }

          location_str = format_location(bp_file, bp_line)
          if condition
            puts "  Breakpoint \e[1m##{id}\e[0m ustawiony: #{location_str} \e[90m(jezeli #{condition})\e[0m"
          else
            puts "  Breakpoint \e[1m##{id}\e[0m ustawiony: #{location_str}"
          end
        end

        def remove_breakpoint(args)
          id = args.strip.to_i
          bp = @breakpoint_list[id]

          unless bp
            puts "  Błąd: Nie znaleziono breakpointa ##{id}."
            return
          end

          # Only remove from the Set if no other breakpoint exists at same location
          remaining = @breakpoint_list.any? do |other_id, other_bp|
            other_id != id &&
              other_bp[:file] == bp[:file] &&
              other_bp[:line] == bp[:line]
          end

          unless remaining
            if @breakpoints[bp[:file]]
              @breakpoints[bp[:file]].delete(bp[:line])
              @breakpoints.delete(bp[:file]) if @breakpoints[bp[:file]].empty?
            end
          end

          @breakpoint_list.delete(id)
          puts "  Usunięto breakpoint ##{id}: #{format_location(bp[:file], bp[:line])}"
        end

        def list_breakpoints
          if @breakpoint_list.empty?
            puts "  (brak breakpointów)"
            return
          end

          puts "  \e[1m[Breakpointy]\e[0m"
          @breakpoint_list.each do |id, bp|
            line = "    ##{id}  #{format_location(bp[:file], bp[:line])}"
            line += "  \e[90mjezeli #{bp[:condition]}\e[0m" if bp[:condition]
            puts line
          end
        end

        def breakpoint_at?(file, line)
          return false unless @breakpoints[file]
          @breakpoints[file].include?(line)
        end

        # Returns the first matching breakpoint info for a file:line
        def find_breakpoint_info(file, line)
          @breakpoint_list.values.find do |bp|
            bp[:file] == file && bp[:line] == line
          end
        end

        # Checks if a breakpoint at file:line should actually trigger.
        # For unconditional breakpoints — always true.
        # For conditional breakpoints — evaluates the condition in current env.
        def breakpoint_hit?(file, line, env)
          return false unless breakpoint_at?(file, line)

          # Find all breakpoints at this location
          matching = @breakpoint_list.values.select do |bp|
            bp[:file] == file && bp[:line] == line
          end

          matching.any? do |bp|
            if bp[:condition]
              # Evaluate condition — only pause if truthy
              result = silent_evaluate(bp[:condition], env)
              result && result[0] == :type_bool && result[1] == BOOL_TRUE
            else
              true  # unconditional breakpoint always triggers
            end
          end
        end

        # ── Watch expressions ────────────────────────────────────────────

        def add_watch(expr_str)
          id = @next_watch_id
          @next_watch_id += 1
          @watch_list[id] = expr_str

          puts "  Watch \e[1m##{id}\e[0m dodany: \e[90m#{expr_str}\e[0m"
        end

        def remove_watch(args)
          id = args.strip.to_i
          expr = @watch_list[id]

          unless expr
            puts "  Błąd: Nie znaleziono watcha ##{id}."
            return
          end

          @watch_list.delete(id)
          puts "  Usunięto watch ##{id}: \e[90m#{expr}\e[0m"
        end

        def list_watches
          if @watch_list.empty?
            puts "  (brak obserwowanych wyrażeń)"
            return
          end

          puts "  \e[1m[Obserwowane wyrażenia]\e[0m"
          @watch_list.each do |id, expr|
            puts "    ##{id}  \e[90m#{expr}\e[0m"
          end
        end

        # Displays all watch expressions with their current values.
        # Called automatically at each pause point.
        def display_watches(env)
          return if @watch_list.empty?

          puts "  \e[1m[Watch]\e[0m"
          @watch_list.each do |id, expr|
            result = silent_evaluate(expr, env)
            if result && result.is_a?(Array) && result.size == 2
              formatted = format_debug_value(result[0], result[1])
              puts "    ##{id} #{expr} = #{formatted}"
            else
              puts "    ##{id} #{expr} = \e[31m<błąd ewaluacji>\e[0m"
            end
          end
        end

        # ── Help ─────────────────────────────────────────────────────────

        def display_help
          puts <<~HELP

            \e[1mKomendy debuggera:\e[0m

            \e[1mKontrola wykonania:\e[0m
              dalej (d)         Kontynuuj do następnego breakpointa
              krok (k)          Krok do przodu (wchodzi w funkcje)
              nastepna (n)      Następna linia (nie wchodzi w funkcje)
              wyjdz (w)         Wyjdź z bieżącej funkcji

            \e[1mInspekcja:\e[0m
              zmienne (z)              Pokaż zmienne w bieżącym zakresie
              zmienne wszystkie        Pokaż zmienne ze wszystkich zakresów
              stos (s)                 Pokaż stos wywołań
              kod [N]                  Pokaż kod źródłowy (N linii kontekstu, domyślnie 5)
              p <wyrażenie>            Ewaluuj wyrażenie AlexScript
              <wyrażenie>              Ewaluuj wyrażenie (skrót bez 'p')

            \e[1mBreakpointy:\e[0m
              ustaw <linia>                     Ustaw breakpoint
              ustaw <plik>:<linia>              Ustaw breakpoint w innym pliku
              ustaw <linia> jezeli <warunek>    Ustaw warunkowy breakpoint
              usun <numer>                      Usuń breakpoint
              punkty                            Lista breakpointów

            \e[1mWatch:\e[0m
              obserwuj <wyrażenie>     Dodaj wyrażenie do obserwacji
              obserwuj                 Lista obserwowanych wyrażeń
              usun_obserwuj <numer>    Usuń wyrażenie z obserwacji

            \e[1mInne:\e[0m
              koniec            Zakończ debugger i kontynuuj program
              pomoc (h, ?)      Pokaż tę pomoc
          HELP
        end

        # ── Formatting helpers ───────────────────────────────────────────

        def format_location(file, line)
          if file && file != 'main'
            filename = File.basename(file)
            "\e[1m#{filename}:#{line}\e[0m"
          elsif line
            "\e[1mlinia #{line}\e[0m"
          else
            "<nieznana lokalizacja>"
          end
        end

        # Formats an AlexScript value for display in the debugger.
        def format_debug_value(type, value)
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
            format_debug_array(value)
          when :type_object
            format_debug_object(value)
          when :type_instance
            class_name = value[:class_name] rescue '?'
            "\e[35m<#{class_name} instancja>\e[0m"
          when :type_function
            "\e[35m<funkcja>\e[0m"
          else
            value.inspect
          end
        end

        def format_debug_array(arr)
          return "\e[90m[]\e[0m" unless arr.is_a?(Array)
          return "[... #{arr.size} elementów]" if arr.size > 10

          elements = arr.first(10).map do |el|
            if el.is_a?(Hash) && el[:type]
              format_debug_value(el[:type], el[:value])
            else
              el.inspect
            end
          end

          "[#{elements.join(', ')}]"
        end

        def format_debug_object(obj)
          return "\e[90m{}\e[0m" unless obj.is_a?(Hash)
          return "{... #{obj.size} kluczy}" if obj.size > 8

          pairs = obj.first(8).map do |key, val|
            if val.is_a?(Hash) && val[:type]
              "\"#{key}\": #{format_debug_value(val[:type], val[:value])}"
            else
              "\"#{key}\": #{val.inspect}"
            end
          end

          "{#{pairs.join(', ')}}"
        end
      end
    end
  end
end