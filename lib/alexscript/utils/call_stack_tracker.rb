module AlexScript
  module Utils
    # ==========================================================================
    # CALL STACK TRACKER - Singleton tracker for function/method calls
    # ==========================================================================
    
    class CallStackTracker
      @stack = []
      @enabled = true
      
      class << self
        attr_accessor :enabled
        
        # Push new call frame onto stack
        def push(type, name, file = nil, line = nil)
          return unless @enabled
          
          @stack << {
            type: type,        # :function, :method, :constructor, :static_method
            name: name,        # function/method name
            file: file || ContextTracker.current_file,
            line: line || ContextTracker.current_line,
            class_name: type == :method || type == :constructor ? 
                       ContextTracker.current_class_name : nil
          }
        end
        
        # Pop call frame from stack
        def pop
          return unless @enabled
          @stack.pop
        end
        
        # Get current stack as array (for exception reporting)
        def current_stack
          @stack.dup
        end
        
        # Clear entire stack (for testing/reset)
        def clear
          @stack.clear
        end
        
        # Get stack depth
        def depth
          @stack.size
        end
        
        # Format stack for display
        def format_stack(stack = nil)
          stack ||= @stack
          
          stack.reverse.map.with_index do |frame, idx|
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