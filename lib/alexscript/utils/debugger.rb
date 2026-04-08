# frozen_string_literal: true

require 'readline'
require 'set'

module AlexScript
  module Utils
    class Debugger
      # ── State ──────────────────────────────────────────────────────────────
      @mode = :inactive
      @breakpoints = {}        # { file_path => Set<line_number> }
      @next_id = 1
      @target_depth = nil
      @last_file = nil
      @last_line = nil
      @interpreter = nil
      @breakpoint_list = {}    # { id => { file:, line:, condition: } }

      # Watch expressions
      @watch_list = {}         # { id => String }
      @next_watch_id = 1

      # Method breakpoints
      @method_breakpoints = {} # { id => { key: "Klasa#metoda", class_name:, method_name: } }
      @next_method_bp_id = 1
      @method_bp_fired = {}   # { "key" => depth } — anti-re-trigger

      # Variable tracking
      @tracked_vars = {}       # { id => { name:, last_snapshot:, last_formatted: } }
      @next_track_id = 1

      # Logpoints
      @logpoints = {}          # { file => { line => [{ id:, expr: }] } }
      @logpoint_list = {}      # { id => { file:, line:, expr: } }
      @next_log_id = 1

      PROMPT = 'debug> '

      class << self
        attr_reader :mode

        def stepping?
          @mode != :inactive
        end

        # ── Activation ───────────────────────────────────────────────────

        def activate!(node, env, interpreter)
          @interpreter = interpreter
          file = ContextTracker.current_file
          line = node.line

          puts "\n\e[31m⏺\e[0m  debug() w #{format_location(file, line)}"
          display_source_context(file, line)
          display_watches(env)

          @mode = :step
          @last_file = file
          @last_line = line

          run_repl(env, file, line)
        end

        # ── Hook ─────────────────────────────────────────────────────────

        def check(node, env, interpreter)
          return unless node.respond_to?(:line) && node.line
          @interpreter = interpreter

          file = ContextTracker.current_file
          line = node.line

          return if file == @last_file && line == @last_line

          # 1. Logpoints — always process, never pause
          process_logpoints(file, line, env)

          # 2. Track variable changes
          var_changes = check_tracked_variables(env)

          # 3. Cleanup method breakpoint flags
          cleanup_method_bp_flags

          # 4. Determine if we should pause
          should_pause = case @mode
                         when :step
                           true
                         when :next
                           CallStackTracker.depth <= @target_depth
                         when :step_out
                           CallStackTracker.depth < @target_depth
                         when :continue
                           breakpoint_hit?(file, line, env) ||
                             method_breakpoint_hit? ||
                             var_changes
                         else
                           false
                         end

          return unless should_pause

          @last_file = file
          @last_line = line

          # Display pause reason
          display_pause_reason(file, line, env, var_changes)
          display_source_context(file, line)
          display_variable_changes(var_changes) if var_changes
          display_watches(env)
          run_repl(env, file, line)
        end

        # ── Reset ────────────────────────────────────────────────────────

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
          @method_breakpoints.clear
          @next_method_bp_id = 1
          @method_bp_fired.clear
          @tracked_vars.clear
          @next_track_id = 1
          @logpoints.clear
          @logpoint_list.clear
          @next_log_id = 1
        end

        private

        # ── Pause reason display ─────────────────────────────────────────

        def display_pause_reason(file, line, env, var_changes)
          if var_changes
            puts "\n\e[35m⏸\e[0m  Zmiana zmiennej w #{format_location(file, line)}"
          elsif @mode == :continue && method_breakpoint_match
            mbp = method_breakpoint_match
            puts "\n\e[33m⏸\e[0m  Breakpoint metody: \e[1m#{mbp}\e[0m w #{format_location(file, line)}"
          elsif @mode == :continue && breakpoint_at?(file, line)
            bp_info = find_breakpoint_info(file, line)
            if bp_info && bp_info[:condition]
              puts "\n\e[33m⏸\e[0m  Breakpoint warunkowy w #{format_location(file, line)} \e[90m(#{bp_info[:condition]})\e[0m"
            else
              puts "\n\e[33m⏸\e[0m  Breakpoint w #{format_location(file, line)}"
            end
          else
            puts "\n\e[33m⏸\e[0m  #{format_location(file, line)}"
          end
        end

        # ── REPL ─────────────────────────────────────────────────────────

        def run_repl(env, file, line)
          loop do
            input = Readline.readline(PROMPT, true)

            if input.nil?
              puts ""
              handle_continue
              break
            end

            input = input.strip
            next if input.empty?

            if Readline::HISTORY.length > 1 &&
               Readline::HISTORY[-1] == Readline::HISTORY[-2]
              Readline::HISTORY.pop
            end

            should_break = execute_command(input, env, file, line)
            break if should_break
          end
        end

        def execute_command(input, env, file, line)
          parts = input.split(/\s+/, 2)
          cmd = parts[0]
          args = parts[1]

          case cmd
          # ── Execution control ──
          when 'dalej', 'd'
            handle_continue; true
          when 'krok', 'k'
            handle_step; true
          when 'nastepna', 'n'
            handle_next; true
          when 'wyjdz', 'w'
            handle_step_out; true

          # ── Inspection ──
          when 'zmienne', 'z'
            args&.strip == 'wszystkie' ? display_all_scopes(env) : display_variables(env)
            false
          when 'stos', 's'
            display_call_stack; false
          when 'kod'
            ctx = args ? args.to_i : 5
            ctx = 5 if ctx <= 0
            display_source_context(file, line, context: ctx)
            false
          when 'p'
            args && !args.empty? ? evaluate_expression(args, env) : puts("  Użycie: p <wyrażenie>")
            false

          # ── Line breakpoints ──
          when 'ustaw'
            args && !args.empty? ? add_breakpoint(args, file) : puts("  Użycie: ustaw <linia> [jesli <warunek>]")
            false
          when 'usun'
            args && !args.empty? ? remove_breakpoint(args) : puts("  Użycie: usun <numer>")
            false
          when 'punkty'
            list_breakpoints; false

          # ── Method breakpoints ──
          when 'ustaw_metode'
            args && !args.empty? ? add_method_breakpoint(args) : puts("  Użycie: ustaw_metode <Klasa#metoda> lub <funkcja>")
            false
          when 'usun_metode'
            args && !args.empty? ? remove_method_breakpoint(args) : puts("  Użycie: usun_metode <numer>")
            false

          # ── Variable tracking ──
          when 'sledz'
            args && !args.empty? ? add_tracked_variable(args, env) : list_tracked_variables
            false
          when 'usun_sledz'
            args && !args.empty? ? remove_tracked_variable(args) : puts("  Użycie: usun_sledz <numer>")
            false

          # ── Logpoints ──
          when 'loguj'
            args && !args.empty? ? add_logpoint(args, file) : list_logpoints
            false
          when 'usun_loguj'
            args && !args.empty? ? remove_logpoint(args) : puts("  Użycie: usun_loguj <numer>")
            false

          # ── Watch expressions ──
          when 'obserwuj'
            args && !args.empty? ? add_watch(args) : list_watches
            false
          when 'usun_obserwuj'
            args && !args.empty? ? remove_watch(args) : puts("  Użycie: usun_obserwuj <numer>")
            false

          # ── Other ──
          when 'koniec'
            handle_quit; true
          when 'pomoc', 'h', '?'
            display_help; false
          else
            evaluate_expression(input, env); false
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

          locals = collect_local_variables(env)
          unless locals.empty?
            puts "  \e[1m[Zmienne lokalne]\e[0m"
            locals.each do |name, info|
              puts "    #{name} = #{format_debug_value(info[:type], info[:value])}"
            end
            has_output = true
          end

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

        def display_all_scopes(env)
          has_output = false
          current = env
          depth = 0

          while current
            vars = collect_local_variables(current)
            unless vars.empty?
              label = depth == 0 ? "Bieżący zakres" : "Zakres nadrzędny (#{depth})"
              puts "  \e[1m[#{label}]\e[0m"
              vars.each do |name, info|
                puts "    #{name} = #{format_debug_value(info[:type], info[:value])}"
              end
              has_output = true
            end
            depth += 1
            current = current.parent
          end

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

        def collect_local_variables(env)
          result = {}
          env.variables.each do |name, info|
            next if name.start_with?('__')
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
            CallStackTracker.format_stack(stack).each { |frame| puts frame }
          end
        end

        # ── Source code display ──────────────────────────────────────────

        def display_source_context(file, line, context: 3)
          puts SourceCache.display(file, line, context: context)
        end

        # ── Expression evaluation ────────────────────────────────────────

        def evaluate_expression(expr_str, env)
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
              result = @interpreter.interpret!(target, env)
              if result.is_a?(Array) && result.size == 2
                puts "  => #{format_debug_value(result[0], result[1])}"
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

        # ══════════════════════════════════════════════════════════════════
        # LINE BREAKPOINTS
        # ══════════════════════════════════════════════════════════════════

        def add_breakpoint(args, current_file)
          condition = nil
          location_part = args

          jesli_idx = args.index(' jesli ')
          if jesli_idx
            location_part = args[0...jesli_idx].strip
            condition = args[(jesli_idx + 8)..-1].strip
            if condition.empty?
              puts "  Błąd: Brak warunku po 'jesli'."; return
            end
          end

          if location_part.include?(':')
            parts = location_part.split(':', 2)
            bp_file = parts[0].strip
            bp_line = parts[1].strip.to_i
          else
            bp_file = current_file
            bp_line = location_part.strip.to_i
          end

          if bp_line <= 0
            puts "  Błąd: Nieprawidłowy numer linii."; return
          end

          if condition
            begin
              Core::Lexer.new(condition).tokenize!
            rescue StandardError => e
              puts "  \e[31mBłąd składni warunku\e[0m: #{e.message}"; return
            end
          end

          @breakpoints[bp_file] ||= Set.new
          @breakpoints[bp_file].add(bp_line)

          id = @next_id; @next_id += 1
          @breakpoint_list[id] = { file: bp_file, line: bp_line, condition: condition }

          loc = format_location(bp_file, bp_line)
          suffix = condition ? " \e[90m(jesli #{condition})\e[0m" : ""
          puts "  Breakpoint \e[1m##{id}\e[0m ustawiony: #{loc}#{suffix}"
        end

        def remove_breakpoint(args)
          id = args.strip.to_i
          bp = @breakpoint_list[id]
          unless bp
            puts "  Błąd: Nie znaleziono breakpointa ##{id}."; return
          end

          remaining = @breakpoint_list.any? { |oid, obp| oid != id && obp[:file] == bp[:file] && obp[:line] == bp[:line] }
          unless remaining
            @breakpoints[bp[:file]]&.delete(bp[:line])
            @breakpoints.delete(bp[:file]) if @breakpoints[bp[:file]]&.empty?
          end

          @breakpoint_list.delete(id)
          puts "  Usunięto breakpoint ##{id}: #{format_location(bp[:file], bp[:line])}"
        end

        def list_breakpoints
          has_any = false

          unless @breakpoint_list.empty?
            puts "  \e[1m[Breakpointy liniowe]\e[0m"
            @breakpoint_list.each do |id, bp|
              line = "    ##{id}  #{format_location(bp[:file], bp[:line])}"
              line += "  \e[90mjesli #{bp[:condition]}\e[0m" if bp[:condition]
              puts line
            end
            has_any = true
          end

          unless @method_breakpoints.empty?
            puts "  \e[1m[Breakpointy metod]\e[0m"
            @method_breakpoints.each do |id, bp|
              puts "    #M#{id}  \e[1m#{bp[:key]}\e[0m"
            end
            has_any = true
          end

          unless @logpoint_list.empty?
            puts "  \e[1m[Logpointy]\e[0m"
            @logpoint_list.each do |id, lp|
              puts "    #L#{id}  #{format_location(lp[:file], lp[:line])} → \e[90m#{lp[:expr]}\e[0m"
            end
            has_any = true
          end

          puts "  (brak breakpointów)" unless has_any
        end

        def breakpoint_at?(file, line)
          @breakpoints[file]&.include?(line) || false
        end

        def find_breakpoint_info(file, line)
          @breakpoint_list.values.find { |bp| bp[:file] == file && bp[:line] == line }
        end

        def breakpoint_hit?(file, line, env)
          return false unless breakpoint_at?(file, line)

          matching = @breakpoint_list.values.select { |bp| bp[:file] == file && bp[:line] == line }
          matching.any? do |bp|
            if bp[:condition]
              result = silent_evaluate(bp[:condition], env)
              result && result[0] == :type_bool && result[1] == BOOL_TRUE
            else
              true
            end
          end
        end

        # ══════════════════════════════════════════════════════════════════
        # METHOD BREAKPOINTS
        # ══════════════════════════════════════════════════════════════════

        def add_method_breakpoint(args)
          name = args.strip

          if name.include?('#')
            parts = name.split('#', 2)
            class_name = parts[0]
            method_name = parts[1]
            key = "#{class_name}##{method_name}"
          elsif name.include?('.')
            parts = name.split('.', 2)
            class_name = parts[0]
            method_name = parts[1]
            key = "#{class_name}.#{method_name}"
          else
            class_name = nil
            method_name = name
            key = name
          end

          # Check for duplicates
          if @method_breakpoints.values.any? { |bp| bp[:key] == key }
            puts "  Breakpoint na #{key} już istnieje."; return
          end

          id = @next_method_bp_id; @next_method_bp_id += 1
          @method_breakpoints[id] = { key: key, class_name: class_name, method_name: method_name }

          puts "  Breakpoint metody \e[1m#M#{id}\e[0m ustawiony: \e[1m#{key}\e[0m"
        end

        def remove_method_breakpoint(args)
          id = args.strip.to_i
          bp = @method_breakpoints[id]
          unless bp
            puts "  Błąd: Nie znaleziono breakpointa metody #M#{id}."; return
          end

          @method_breakpoints.delete(id)
          @method_bp_fired.delete(bp[:key])
          puts "  Usunięto breakpoint metody #M#{id}: #{bp[:key]}"
        end

        # Returns the key of the matching method breakpoint, or nil.
        def method_breakpoint_match
          return nil if @method_breakpoints.empty?

          stack = CallStackTracker.current_stack
          return nil if stack.empty?

          top = stack.last
          frame_key = if top[:class_name]
                        if top[:type] == :static_method
                          "#{top[:class_name]}.#{top[:name]}"
                        else
                          "#{top[:class_name]}##{top[:name]}"
                        end
                      else
                        top[:name]
                      end

          matching = @method_breakpoints.values.find { |bp| bp[:key] == frame_key }
          matching ? frame_key : nil
        end

        # Checks if a method breakpoint should fire (with anti-re-trigger).
        def method_breakpoint_hit?
          key = method_breakpoint_match
          return false unless key

          current_depth = CallStackTracker.depth
          return false if @method_bp_fired[key] == current_depth

          @method_bp_fired[key] = current_depth
          true
        end

        # Clear fired flags for methods we've already left.
        def cleanup_method_bp_flags
          return if @method_bp_fired.empty?
          current_depth = CallStackTracker.depth
          @method_bp_fired.delete_if { |_key, depth| current_depth < depth }
        end

        # ══════════════════════════════════════════════════════════════════
        # VARIABLE TRACKING
        # ══════════════════════════════════════════════════════════════════

        def add_tracked_variable(name, env)
          name = name.strip

          # Take initial snapshot
          result = silent_evaluate(name, env)
          snapshot = result ? "#{result[0]}:#{result[1].inspect}" : nil
          formatted = result ? format_debug_value(result[0], result[1]) : "\e[90m<niedostępna>\e[0m"

          id = @next_track_id; @next_track_id += 1
          @tracked_vars[id] = { name: name, last_snapshot: snapshot, last_formatted: formatted }

          puts "  Śledzenie \e[1m#T#{id}\e[0m dodane: \e[90m#{name}\e[0m (aktualna wartość: #{formatted})"
        end

        def remove_tracked_variable(args)
          id = args.strip.to_i
          info = @tracked_vars[id]
          unless info
            puts "  Błąd: Nie znaleziono śledzenia #T#{id}."; return
          end

          @tracked_vars.delete(id)
          puts "  Usunięto śledzenie #T#{id}: #{info[:name]}"
        end

        def list_tracked_variables
          if @tracked_vars.empty?
            puts "  (brak śledzonych zmiennych)"; return
          end

          puts "  \e[1m[Śledzone zmienne]\e[0m"
          @tracked_vars.each do |id, info|
            puts "    #T#{id}  #{info[:name]} = #{info[:last_formatted]}"
          end
        end

        # Checks all tracked variables for changes. Returns array of change
        # descriptions, or nil if nothing changed.
        def check_tracked_variables(env)
          return nil if @tracked_vars.empty?

          changes = []
          @tracked_vars.each do |id, info|
            result = silent_evaluate(info[:name], env)
            current_snapshot = result ? "#{result[0]}:#{result[1].inspect}" : nil
            current_formatted = result ? format_debug_value(result[0], result[1]) : "\e[90m<niedostępna>\e[0m"

            # Compare with last known value
            if info[:last_snapshot] && info[:last_snapshot] != current_snapshot
              changes << {
                id: id, name: info[:name],
                old: info[:last_formatted],
                new: current_formatted
              }
            end

            info[:last_snapshot] = current_snapshot
            info[:last_formatted] = current_formatted
          end

          changes.empty? ? nil : changes
        end

        def display_variable_changes(changes)
          return unless changes
          puts "  \e[1m[Zmiany zmiennych]\e[0m"
          changes.each do |ch|
            puts "    #T#{ch[:id]} #{ch[:name]}: #{ch[:old]} → #{ch[:new]}"
          end
        end

        # ══════════════════════════════════════════════════════════════════
        # LOGPOINTS
        # ══════════════════════════════════════════════════════════════════

        def add_logpoint(args, current_file)
          # Parse: "10 x + y" or "plik.as:10 x + y"
          parts = args.split(/\s+/, 2)
          location = parts[0]
          expr = parts[1]

          unless expr && !expr.empty?
            puts "  Użycie: loguj <linia> <wyrażenie> lub loguj <plik>:<linia> <wyrażenie>"
            return
          end

          if location.include?(':')
            loc_parts = location.split(':', 2)
            lp_file = loc_parts[0].strip
            lp_line = loc_parts[1].strip.to_i
          else
            lp_file = current_file
            lp_line = location.strip.to_i
          end

          if lp_line <= 0
            puts "  Błąd: Nieprawidłowy numer linii."; return
          end

          # Validate expression syntax
          begin
            Core::Lexer.new(expr).tokenize!
          rescue StandardError => e
            puts "  \e[31mBłąd składni wyrażenia\e[0m: #{e.message}"; return
          end

          id = @next_log_id; @next_log_id += 1
          @logpoint_list[id] = { file: lp_file, line: lp_line, expr: expr }

          @logpoints[lp_file] ||= {}
          @logpoints[lp_file][lp_line] ||= []
          @logpoints[lp_file][lp_line] << { id: id, expr: expr }

          puts "  Logpoint \e[1m#L#{id}\e[0m ustawiony: #{format_location(lp_file, lp_line)} → \e[90m#{expr}\e[0m"
        end

        def remove_logpoint(args)
          id = args.strip.to_i
          lp = @logpoint_list[id]
          unless lp
            puts "  Błąd: Nie znaleziono logpointa #L#{id}."; return
          end

          # Remove from logpoints hash
          if @logpoints[lp[:file]] && @logpoints[lp[:file]][lp[:line]]
            @logpoints[lp[:file]][lp[:line]].reject! { |entry| entry[:id] == id }
            if @logpoints[lp[:file]][lp[:line]].empty?
              @logpoints[lp[:file]].delete(lp[:line])
              @logpoints.delete(lp[:file]) if @logpoints[lp[:file]].empty?
            end
          end

          @logpoint_list.delete(id)
          puts "  Usunięto logpoint #L#{id}: #{format_location(lp[:file], lp[:line])}"
        end

        def list_logpoints
          if @logpoint_list.empty?
            puts "  (brak logpointów)"; return
          end

          puts "  \e[1m[Logpointy]\e[0m"
          @logpoint_list.each do |id, lp|
            puts "    #L#{id}  #{format_location(lp[:file], lp[:line])} → \e[90m#{lp[:expr]}\e[0m"
          end
        end

        # Processes logpoints at the current file:line. Evaluates and prints
        # expressions without pausing execution.
        def process_logpoints(file, line, env)
          return unless @logpoints[file] && @logpoints[file][line]

          @logpoints[file][line].each do |lp|
            result = silent_evaluate(lp[:expr], env)
            if result && result.is_a?(Array) && result.size == 2
              formatted = format_debug_value(result[0], result[1])
              puts "  \e[34m◆\e[0m \e[90m[LOG #{File.basename(file.to_s)}:#{line}]\e[0m #{formatted}"
            else
              puts "  \e[34m◆\e[0m \e[90m[LOG #{File.basename(file.to_s)}:#{line}]\e[0m \e[31m<błąd>\e[0m"
            end
          end
        end

        # ══════════════════════════════════════════════════════════════════
        # WATCH EXPRESSIONS
        # ══════════════════════════════════════════════════════════════════

        def add_watch(expr_str)
          id = @next_watch_id; @next_watch_id += 1
          @watch_list[id] = expr_str
          puts "  Watch \e[1m##{id}\e[0m dodany: \e[90m#{expr_str}\e[0m"
        end

        def remove_watch(args)
          id = args.strip.to_i
          expr = @watch_list[id]
          unless expr
            puts "  Błąd: Nie znaleziono watcha ##{id}."; return
          end
          @watch_list.delete(id)
          puts "  Usunięto watch ##{id}: \e[90m#{expr}\e[0m"
        end

        def list_watches
          if @watch_list.empty?
            puts "  (brak obserwowanych wyrażeń)"; return
          end
          puts "  \e[1m[Obserwowane wyrażenia]\e[0m"
          @watch_list.each { |id, expr| puts "    ##{id}  \e[90m#{expr}\e[0m" }
        end

        def display_watches(env)
          return if @watch_list.empty?
          puts "  \e[1m[Watch]\e[0m"
          @watch_list.each do |id, expr|
            result = silent_evaluate(expr, env)
            if result && result.is_a?(Array) && result.size == 2
              puts "    ##{id} #{expr} = #{format_debug_value(result[0], result[1])}"
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
              kod [N]                  Pokaż kod źródłowy (N linii kontekstu)
              p <wyrażenie>            Ewaluuj wyrażenie AlexScript
              <wyrażenie>              Ewaluuj wyrażenie (skrót bez 'p')

            \e[1mBreakpointy liniowe:\e[0m
              ustaw <linia>                     Ustaw breakpoint
              ustaw <plik>:<linia>              Ustaw w innym pliku
              ustaw <linia> jesli <warunek>    Warunkowy breakpoint
              usun <numer>                      Usuń breakpoint
              punkty                            Lista wszystkich breakpointów

            \e[1mBreakpointy metod:\e[0m
              ustaw_metode <Klasa#metoda>       Breakpoint na metodzie instancji
              ustaw_metode <Klasa.metoda>       Breakpoint na metodzie statycznej
              ustaw_metode <funkcja>            Breakpoint na funkcji
              usun_metode <numer>               Usuń breakpoint metody

            \e[1mŚledzenie zmiennych:\e[0m
              sledz <zmienna>          Śledź zmianę wartości zmiennej
              sledz                    Lista śledzonych zmiennych
              usun_sledz <numer>       Usuń śledzenie

            \e[1mLogpointy:\e[0m
              loguj <linia> <wyrażenie>         Logpoint w bieżącym pliku
              loguj <plik>:<linia> <wyrażenie>  Logpoint w innym pliku
              loguj                             Lista logpointów
              usun_loguj <numer>                Usuń logpoint

            \e[1mWatch:\e[0m
              obserwuj <wyrażenie>     Dodaj do obserwacji (auto-wyświetlanie)
              obserwuj                 Lista obserwowanych wyrażeń
              usun_obserwuj <numer>    Usuń z obserwacji

            \e[1mInne:\e[0m
              koniec            Zakończ debugger i kontynuuj program
              pomoc (h, ?)      Pokaż tę pomoc
          HELP
        end

        # ── Formatting helpers ───────────────────────────────────────────

        def format_location(file, line)
          if file && file != 'main'
            "\e[1m#{File.basename(file)}:#{line}\e[0m"
          elsif line
            "\e[1mlinia #{line}\e[0m"
          else
            "<nieznana lokalizacja>"
          end
        end

        def format_debug_value(type, value)
          case type
          when :type_int    then "\e[36m#{value}\e[0m"
          when :type_float  then "\e[36m#{value}\e[0m"
          when :type_string then "\e[32m\"#{value}\"\e[0m"
          when :type_bool
            "\e[33m#{value == BOOL_TRUE ? 'prawda' : 'falsz'}\e[0m"
          when :type_null     then "\e[90mnic\e[0m"
          when :type_array    then format_debug_array(value)
          when :type_object   then format_debug_object(value)
          when :type_instance then "\e[35m<#{value[:class_name] rescue '?'} instancja>\e[0m"
          when :type_function then "\e[35m<funkcja>\e[0m"
          else value.inspect
          end
        end

        def format_debug_array(arr)
          return "\e[90m[]\e[0m" unless arr.is_a?(Array)
          return "[... #{arr.size} elementów]" if arr.size > 10
          elements = arr.first(10).map { |el| el.is_a?(Hash) && el[:type] ? format_debug_value(el[:type], el[:value]) : el.inspect }
          "[#{elements.join(', ')}]"
        end

        def format_debug_object(obj)
          return "\e[90m{}\e[0m" unless obj.is_a?(Hash)
          return "{... #{obj.size} kluczy}" if obj.size > 8
          pairs = obj.first(8).map { |k, v| v.is_a?(Hash) && v[:type] ? "\"#{k}\": #{format_debug_value(v[:type], v[:value])}" : "\"#{k}\": #{v.inspect}" }
          "{#{pairs.join(', ')}}"
        end
      end
    end
  end
end