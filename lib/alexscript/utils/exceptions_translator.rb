# frozen_string_literal: true

# This class in responsible for translating Ruby Exceptions from English to Polish and replace them with AS native ones
module AlexScript
  module Utils
    class ExceptionsTranslator    
      # sirect mapping: Ruby exception class → AS exception name
      EXCEPTION_MAP = {
        NoMethodError => 'BladMetody',
        NameError => 'BladNazwy',
        TypeError => 'BladTypu',
        ArgumentError => 'BladArgumentu',
        ZeroDivisionError => 'BladDzieleniaPrzezZero',
        SyntaxError => 'BladSkladni',
        RangeError => 'BladZakresu',
        StandardError => 'BladWykonania'
      }.freeze

      # message translations (EN → PL)
      MESSAGE_TRANSLATIONS = {
        'division by zero' => 'dzielenie przez zero',
        'undefined method' => 'niezdefiniowana metoda',
        'undefined local variable or method' => 'niezdefiniowana zmienna lub metoda',
        'wrong number of arguments' => 'niewlasciwa liczba argumentow',
        'no implicit conversion' => 'brak konwersji',
        "can't convert" => 'nie mozna przekonwertowac',
        'unexpected token' => 'nieoczekiwany token',
        'given' => 'dano',
        'expected' => 'oczekiwano',
        'stack level too deep' => 'zbyt glebokie zagniezdzenie stosu',
        'index out of bounds' => 'indeks poza zakresem',
        'out of bounds' => 'poza zakresem',
        'for an instance of' => 'dla instancji',
        'for' => 'dla'
      }.freeze

      def self.translate(exception, additional_message = nil)
        return exception if exception.is_a?(AlexScriptError)

        # Honor RuntimeError exceptions decorated with @alexscript_class_name
        # by raise_exception_from_instance — these are AS exception instances
        # in disguise and must keep their identity through the async path.
        if exception.instance_variable_defined?(:@alexscript_class_name)
          class_name = exception.instance_variable_get(:@alexscript_class_name)
          new_err = AlexScriptError.new(class_name, exception.message)
          # Preserve the underlying instance for handlers that want full context
          if exception.instance_variable_defined?(:@alexscript_instance)
            new_err.instance_variable_set(
              :@alexscript_instance,
              exception.instance_variable_get(:@alexscript_instance)
            )
          end
          return new_err
        end

        exception_type = EXCEPTION_MAP[exception.class] || 'BladWykonania'
        translated_message = translate_message(exception.message)
        translated_message += " (#{additional_message})" if additional_message
        AlexScriptError.new(exception_type, translated_message, ContextTracker.current_line)
      end

      def self.translate_message(message)
        return message unless message.is_a?(String)
        
        result = message.dup
        MESSAGE_TRANSLATIONS.each do |en, pl|
          result.gsub!(/#{Regexp.escape(en)}/i, pl)
        end
        result
      end
    end
  end
end