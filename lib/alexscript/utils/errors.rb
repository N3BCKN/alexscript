# frozen_string_literal: true

module AlexScript
  module Utils
    # def self.lexing_error(message, line)
    #   puts "[line: #{line}], #{message}".colorize(:red)
    #   exit(1)
    # end

    # def self.parse_error(message, line)
    #   puts "[line: #{line}], #{message}".colorize(:red)
    #   exit(1)
    # end

    # def self.runtime_error(message, line = nil, file = nil)
    #   line ||= ContextTracker.current_line
    #   file ||= ContextTracker.current_file
    #   file_info = file ? "#{file}" : ''
    #   puts "[#{file_info}, line: #{line}] -> " + message.colorize(:red)
    #   exit(1)
    # end

    def self.lexing_error(message, line = nil)
      raise BladSkladni.new(message, line)
    end

    def self.parse_error(message, line = nil)
      raise BladSkladni.new(message, line)
    end

    def self.runtime_error(message, line = nil)
      exception_class = determine_exception_class(message)
      raise exception_class.new(message, line)
    end

    def self.determine_exception_class(message)
      case message
      when /division by zero/i, /dzielenie przez zero/i
        BladDzieleniaPrzezZero
      when /undefined method/i, /niezdefiniowana metoda/i, /unknown method/i
        BladMetody
      when  /niezadeklarowany identyfikator/i,  /niezdefiniowana zmienna/i,
        /nie zostala zadeklarowana w obecnym zakresie/i, /Niepoprawna wartosc funkcji/i
        BladNazwy
      when /type/i, /typ/i
        BladTypu
      when /array index/i, /indeks tablicy/i, /index out of bounds/i, /indeks poza zakresem/i
        BladZakresu
      when /argument/i
        BladArgumentu
      when /Blad importu/i
        BladImportu
      else
        BladWykonania
      end
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

    class WyjatekPodstawowy < StandardError
      attr_reader :message, :line, :file
      
      def initialize(message, line = nil, file = nil)
        # Translate the message when creating the exception
        @message = ExceptionsTranslator.translate_message(message) || message
        @line = line || Utils::ContextTracker.current_line
        @file = file || Utils::ContextTracker.current_file
        super(@message)
      end
      
      def to_s
        location = ""
        location += "w pliku #{@file} " if @file
        location += "w linii #{@line}" if @line
        
        "#{self.class.name.split('::').last}: #{@message} #{location}"
      end
    end

    class BladWykonania < WyjatekPodstawowy; end
    class BladSkladni < WyjatekPodstawowy; end
    class BladTypu < WyjatekPodstawowy; end
    class BladZakresu < WyjatekPodstawowy; end
    class BladMetody < WyjatekPodstawowy; end
    class BladNazwy < WyjatekPodstawowy; end
    class BladArgumentu < WyjatekPodstawowy; end
    class BladImportu < WyjatekPodstawowy; end
    class BladDzieleniaPrzezZero < WyjatekPodstawowy; end
  end
end
