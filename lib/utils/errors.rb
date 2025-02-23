# frozen_string_literal: true

module AlexScript
  module Utils
    def self.lexing_error(message, line)
      puts "[line: #{line}], #{message}".colorize(:red)
      exit(1)
    end

    def self.parse_error(message, line)
      puts "[line: #{line}], #{message}".colorize(:red)
      exit(1)
    end

    def self.runtime_error(message, line = nil, file = nil)
      line ||= ContextTracker.current_line
      file ||= ContextTracker.current_file
      file_info = file ? "#{file}" : ''
      puts "[#{file_info}, line: #{line}] -> " + message.colorize(:red)
      exit(1)
    end

    class ReturnError < StandardError
      attr_reader :value

      def initialize(value)
        @value = value
        super()
      end
    end

    class BreakException < StandardError; end
    class ContinueException < StandardError; end
  end
end
