# frozen_string_literal: true

# This class in responsible for translating Ruby Exceptions from English to Polish and replace them with AS native ones
module AlexScript
    module Utils
      class ExceptionsTranslator    
				EXCEPTIONS_MAP = {
					NoMethodError => 'BladMetody',
					NameError => 'BladNazwy',
					TypeError => 'BladTypu',
					ArgumentError => 'BladArgumentu',
					ZeroDivisionError => 'BladDzieleniaPrzezZero',
					SyntaxError => 'BladSkladni',
					StandardError => 'BladWykonania',
					Exception => 'WyjatekPodstawowy'
				}.freeze
  
				ERROR_MESSAGES = {
					'Division by zero' => 'Dzielenie przez zero',
					'Error executing method' => 'blad podczas wykonywania metody',
					'undefined method' => 'niezdefiniowana metoda',
					'undefined local variable or method' => 'niezdefiniowana zmienna lokalna lub metoda',
					'wrong number of arguments' => 'niewlasciwa liczba argumentow',
					'no implicit conversion of' => 'brak mozliwosci konwersji',
					"can't convert" => 'nie mozna przekonwertowac',
					'unexpected token' => 'nieoczekiwany token',
					'given' => 'dano',
					'expected' => 'oczekiwano',
					'stack level too deep' => 'zbyt glebokie zagniezdzenie stosu',
					'Index out of bounds' => 'Indeks poza zakresem',
					'Undeclared identifier' => 'Niezadeklarowany identyfikator',
					'Variable must be declared' => 'Zmienna musi zostać zadeklarowana',
					'Uninitialized identifier' => 'Niezainicjalizowany identyfikator',
					'Condition must be boolean or null' => 'Warunek musi byc typu boolean lub null',
					'Array index must be an integer' => 'Indeks tablicy musi byc liczbą całkowitą',
					'Object key must be a string' => 'Klucz obiektu musi byc ciagiem znakow',
					'Undefined key' => 'Niezdefiniowany klucz',
					'Cannot call method on undefined object' => 'Nie można wywolac metody na niezdefiniowanym obiekcie',
					'Maximum recursion depth' => 'Maksymalna głębokosc rekurencji',
					'stack is too deep' => 'zbyt glebokie zagniezdzenie stosu',
					'exceeded' => 'przekroczono'
				}.freeze
  
				def self.translate(exception, additional_message = nil)
					if exception.is_a?(AlexScriptError)
						# Already an AlexScript error, just pass through
						return exception
					end
					
					original_message = exception.message
					translated_message = translate_message(original_message)
					exception_type = find_exception_type(exception)
					
					translated_message += " (#{additional_message})" if additional_message
					
					line = Utils::ContextTracker.current_line
					file = Utils::ContextTracker.current_file
					
					# Return AS instead of creating Ruby exception instance
					AlexScriptError.new(exception_type, translated_message, line)
				end
  
				def self.find_exception_type(excp)
					case excp
					when NoMethodError then 'BladMetody'
					when NameError then 'BladNazwy'
					when TypeError then 'BladTypu'
					when ArgumentError then 'BladArgumentu'
					when ZeroDivisionError then 'BladDzieleniaPrzezZero'
					when SyntaxError then 'BladSkladni'
					when StandardError then 'BladWykonania'
					else 'WyjatekPodstawowy'
					end
				end
  
				def self.translate_message(message)
					return nil unless message.is_a?(String)
					
					translated = message.dup
					ERROR_MESSAGES.each do |eng, pol|
						translated.gsub!(eng, pol) if translated.include?(eng)
					end
					
					translated
				end
      end
    end
  end