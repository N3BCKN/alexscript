# frozen_string_literal: true

module AlexScript
  module Utils
    # ContextTracker is responsible for tracking the execution context of the interpreter,
    # including current file, line number, method name, and class context.
    # This allows for more accurate error reporting and proper implementation of
    # language features that depend on context, such as the 'super' keyword.
    #
    # State is stored per-fiber via Fiber[:alex_ctx_*]. In synchronous code
    # behaviour is identical to the previous class-variable implementation,
    # because there is only one fiber. Under Ruby Fibers, each fiber sees its
    # own view of the execution context — essential for async correctness.
    class ContextTracker
      @instance = new

      private_class_method :new

      class << self
        # line 

        def current_line
          Fiber[:alex_ctx_line]
        end

        def current_line=(value)
          Fiber[:alex_ctx_line] = value
        end

        # file 

        def current_file
          Fiber[:alex_ctx_file]
        end

        def current_file=(value)
          Fiber[:alex_ctx_file] = value
        end

        # method name 

        def current_method_name
          Fiber[:alex_ctx_method_name]
        end

        def current_method_name=(value)
          Fiber[:alex_ctx_method_name] = value
        end

        # class name 

        def current_class_name
          Fiber[:alex_ctx_class_name]
        end

        def current_class_name=(value)
          Fiber[:alex_ctx_class_name] = value
        end

        # scoped context helpers 

        # Tracks method call context, ensuring current_method_name is set during
        # execution and properly restored afterward.
        def track_method_call(method_name)
          old_method = current_method_name
          self.current_method_name = method_name
          yield
        ensure
          self.current_method_name = old_method
        end

        # Tracks class context, ensuring current_class_name is set during
        # execution and properly restored afterward.
        def track_class_context(class_name)
          old_class = current_class_name
          self.current_class_name = class_name
          yield
        ensure
          self.current_class_name = old_class
        end
      end
    end
  end
end