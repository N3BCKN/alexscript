# frozen_string_literal: true

module AlexScript
  module Utils
    # ContextTracker is responsible for tracking the execution context of the interpreter,
    # including current file, line number, method name, and class context.
    # This allows for more accurate error reporting and proper implementation of 
    # language features that depend on context, such as the 'super' keyword.
    class ContextTracker
      @instance = new
      @current_line = nil
      @current_file = nil
      @current_method_name = nil
      @current_class_name = nil

      private_class_method :new

      class << self
        attr_accessor :current_line, :current_file, :current_method_name, :current_class_name

        # Tracks method call context, ensuring the current_method_name is set during execution
        # and properly restored afterward
        def track_method_call(method_name)
          old_method = @current_method_name
          @current_method_name = method_name
          yield
        ensure
          @current_method_name = old_method
        end

        # Tracks class context, ensuring the current_class_name is set during execution
        # and properly restored afterward
        def track_class_context(class_name)
          old_class = @current_class_name
          @current_class_name = class_name
          yield
        ensure
          @current_class_name = old_class
        end
      end
    end
  end
end