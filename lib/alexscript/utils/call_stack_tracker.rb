module AlexScript
  module Utils
    # ==========================================================================
    # CALL STACK TRACKER - Singleton tracker for function/method calls
    # ==========================================================================
    
    class CallStackTracker
      # @enabled stays as a plain class ivar — it's a global toggle (config),
      # not execution state, so it doesn't need to be per-fiber.
      @enabled = true

      class << self
        attr_accessor :enabled

        #fiber-local stack accessor 

        # Each fiber gets its own call stack. Ruby's Fiber[:key] inherits
        # values from the parent fiber, so a naive shared Array would be
        # mutated by both parent and child. We detect a fiber boundary by
        # comparing Fiber.current.object_id against a stored owner id; on
        # mismatch (including first access in any fiber), we install a fresh
        # Array in this fiber's storage, which decouples it from the parent.
        def stack
          current_id = Fiber.current.object_id
          if Fiber[:alex_call_stack_owner] != current_id
            Fiber[:alex_call_stack]       = []
            Fiber[:alex_call_stack_owner] = current_id
          end
          Fiber[:alex_call_stack]
        end

        #public API
        def push(type, name, file = nil, line = nil)
          return unless @enabled

          stack << {
            type: type,
            name: name,
            file: file || ContextTracker.current_file,
            line: line || ContextTracker.current_line,
            class_name: (type == :method || type == :constructor) ?
                        ContextTracker.current_class_name : nil
          }
        end

        def pop
          return unless @enabled
          stack.pop
        end

        def current_stack
          stack.dup
        end

        def clear
          stack.clear
        end

        def depth
          stack.size
        end

        def format_stack(s = nil)
          s ||= stack

          s.reverse.map.with_index do |frame, idx|
            format_frame(frame, idx)
          end
        end

        private

        def format_frame(frame, index)
          case frame[:type]
          when :function
            location = format_location(frame[:file], frame[:line])
            "  #{index}: funkcja #{frame[:name]} #{location}"
          when :method
            location = format_location(frame[:file], frame[:line])
            "  #{index}: #{frame[:class_name]}##{frame[:name]} #{location}"
          when :constructor
            location = format_location(frame[:file], frame[:line])
            "  #{index}: #{frame[:class_name]}.nowy #{location}"
          when :static_method
            location = format_location(frame[:file], frame[:line])
            "  #{index}: #{frame[:class_name]}.#{frame[:name]} #{location}"
          else
            "  #{index}: <unknown>"
          end
        end

        def format_location(file, line)
          if file && line
            filename = File.basename(file)
            "(#{filename}:#{line})"
          elsif file
            "(#{File.basename(file)})"
          elsif line
            "(line #{line})"
          else
            ""
          end
        end
      end
    end
  end
end