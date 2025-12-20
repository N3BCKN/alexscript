# frozen_string_literal: true

module AlexScript
  module Utils
    # Helper methods for error reporting
    def self.lexing_error(message, line = nil)
      raise_alexscript_exception('BladSkladni', message, line)
    end

    def self.parse_error(message, line = nil)
      raise_alexscript_exception('BladSkladni', message, line)
    end

    def self.runtime_error(message, line = nil)
      exception_class_name = determine_exception_class(message)
      raise_alexscript_exception(exception_class_name, message, line)
    end

    private

    def self.raise_alexscript_exception(class_name, message, line = nil)
      # line can be nil - that's OK, AlexScriptError handles it
      raise AlexScriptError.new(class_name, message, line)
    end

    def self.determine_exception_class(message)
      case message
      when /division by zero/i, /dzielenie przez zero/i
        'BladDzieleniaPrzezZero'
      when /undefined method/i, /niezdefiniowana metoda/i, /unknown method/i
        'BladMetody'
      when /niezadeklarowany identyfikator/i, /niezdefiniowana zmienna/i,
           /nie zostala zadeklarowana w obecnym zakresie/i, /Niepoprawna wartosc funkcji/i
        'BladNazwy'
      when /type/i, /typ/i
        'BladTypu'
      when /array index/i, /indeks tablicy/i, /index out of bounds/i, /indeks poza zakresem/i
        'BladZakresu'
      when /argument/i
        'BladArgumentu'
      when /Blad importu/i
        'BladImportu'
      else
        'BladWykonania'
      end
    end

    # ============================================
    # CONTROL FLOW EXCEPTIONS (for internal use)
    # ============================================
    # These are NOT AlexScript exceptions, they're Ruby exceptions
    # used for control flow (return, break, continue)
    
    class ReturnError < StandardError
      attr_reader :value

      def initialize(value)
        @value = value
        super()
      end
    end

    class BreakException < StandardError; end
    
    class ContinueException < StandardError; end

    # ============================================
    # LIGHTWEIGHT WRAPPER FOR ALEXSCRIPT ERRORS
    # ============================================
    # Used internally to pass AlexScript exception info through Ruby stack
    # Will be converted to actual AlexScript exception instance by interpreter
    
    class AlexScriptError < StandardError
      attr_reader :alexscript_class_name, :message, :line
      
      def initialize(class_name, message, line = nil)
        @alexscript_class_name = class_name
        @message = message
        @line = line
        
        # Build full message with line number
        full_message = if line
                        "#{message} w linii #{line}"
                      else
                        message
                      end
        super(full_message)
      end
    end
  end
end