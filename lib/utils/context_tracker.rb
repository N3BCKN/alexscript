# frozen_string_literal: true

module AlexScript
  module Utils
    class ContextTracker
      @instance = new
      @current_line = nil
      @current_file = nil

      private_class_method :new

      class << self
        attr_accessor :current_line, :current_file
      end
    end
  end
end
