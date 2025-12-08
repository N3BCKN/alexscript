# lib/alexscript/utils/ruby_evaluator.rb
require 'set'

module AlexScript
  module Utils
    class RubyEvaluator
      # Lista dozwolonych moduÅ‚Ã³w i klas
      ALLOWED_MODULES = Set.new([
        'Math', 'Array', 'String', 'Hash', 'Numeric', 'Integer', 'Float', 
        'Time', 'Date', 'Set', 'Kernel', 'Range', 'Socket', 'TCPSocket', 
        'UDPSocket', 'BasicSocket', 'IPSocket'
      ])

      MODULE_TO_LIBRARY = {
        'Socket' => 'socket',
        'TCPSocket' => 'socket',
        'UDPSocket' => 'socket',
        'BasicSocket' => 'socket',
        'IPSocket' => 'socket',
        'JSON' => 'json',
        'CSV' => 'csv',
        'Base64' => 'base64',
        'Zlib' => 'zlib',
        'StringIO' => 'stringio'
      }
      
      # Lista zabronionych metod
      FORBIDDEN_METHODS = Set.new([
        'eval', 'system', 'exec', 'syscall', 'fork', 'spawn', 'backtick', '`',
        'load', 'require', 'require_relative', 'autoload',
        'instance_eval', 'class_eval', 'module_eval',
        'instance_exec', 'class_exec', 'module_exec',
        'define_method', '__send__', 'public_send',
        'method_missing', 'const_set', 'remove_const',
        'instance_variable_get', 'instance_variable_set'
      ])
      
      # Lista dozwolonych bibliotek Ruby do importu
      ALLOWED_REQUIRES = Set.new([
        'socket', 'json', 'csv', 'date', 'time', 'zlib', 'stringio', 'base64', 'fileutils'
      ])
      
      # Śledzenie załadowanych bibliotek według pliku
      @@loaded_libraries = {}

      # Hash przechowujący obiekty Ruby według ID
      @@ruby_objects = {}
      
      # Metoda do importowania biblioteki Ruby
      def self.require_library(library_name, file_path)
        unless ALLOWED_REQUIRES.include?(library_name)
          raise "Niedozwolony import biblioteki Ruby: #{library_name}"
        end
        
        # Inicjalizuj śledzenie dla tego pliku
        @@loaded_libraries[file_path] ||= Set.new
        
        # Jeśli biblioteka już została załadowana dla tego pliku, zwróć success
        return true if @@loaded_libraries[file_path].include?(library_name)
        
        begin
          require library_name
          @@loaded_libraries[file_path].add(library_name)
          true
        rescue LoadError => e
          raise "Nie można załadować biblioteki #{library_name}: #{e.message}"
        end
      end
      
      def self.validate_call(module_path, method_name)
        unless ALLOWED_MODULES.include?(module_path.split('::').first)
          raise "Niedozwolony moduł: #{module_path}"
        end
        
        if FORBIDDEN_METHODS.include?(method_name)
          raise "Niedozwolona metoda: #{method_name}"
        end
        
        true
      end
      
      def self.safe_call(module_path, method_name, args, file_path)
        # Walidacja wywołania
        validate_call(module_path, method_name)

        # Sprawdź, czy trzeba załadować bibliotekę na podstawie nazwy modułu
        main_module = module_path.split('::').first

        if MODULE_TO_LIBRARY.key?(main_module)
          require_library(MODULE_TO_LIBRARY[main_module], file_path)
        end
        
        # Konwersja argumentów na typy Ruby
        ruby_args = convert_to_ruby_value(args)
        
        # Wywołanie metody Ruby lub pobranie stałej
        result = nil
        begin
          # Specjalne przypadki dla metod instancji
          instance_method_classes = {
            'Float' => Float,
            'Integer' => Integer,
            'Numeric' => Numeric,
            'String' => String,
            'Array' => Array,
            'Hash' => Hash
          }
          if instance_method_classes.key?(module_path) && !ruby_args.empty?
            # Metoda instancji - wywołaj ju na pierwszym argumencie
            instance = ruby_args.shift
            klass = instance_method_classes[module_path]
            
            # Sprawdź, czy argument jest odpowiedniego typu
            if instance.is_a?(klass)
              result = instance.send(method_name, *ruby_args)
            else
              # Próba konwersji
              begin
                converted = klass === instance ? instance : klass.new(instance)
                result = converted.send(method_name, *ruby_args)
              rescue StandardError => e
                raise "Nie można wywołać metody #{method_name} na #{module_path}: #{e.message}"
              end
            end
          else
            # Standardowe wywołanie metody klasy lub pobranie stałej
            target = module_path.split('::').inject(Object) do |mod, class_name|
              mod.const_get(class_name)
            end
            
            if module_path == "Float" && method_name == "INFINITY"
              result = Float::INFINITY
            elsif ruby_args.empty? && target.is_a?(Module) && target.const_defined?(method_name.upcase)
              result = target.const_get(method_name)
            else
              result = target.send(method_name, *ruby_args)
            end
          end
        rescue StandardError => e
          raise "Błąd podczas wywołania #{module_path}::#{method_name}: #{e.message}"
        end
        
        
        # Konwersja wyniku na format AlexScript
        # convert_result(result)
        converted_result = convert_result(result)
        { type: converted_result[0], value: converted_result[1] }
      end

      def self.convert_to_ruby_value(args)
        args.map do |arg|
          arg_type = arg[:type]
          arg_value = arg[:value]
          
          # Specjalna obsługa dla obiektu Range
          if arg_type == :type_object && arg_value.is_a?(Hash) && arg_value['_ruby_object']
            # To jest obiekt Ruby przechowywany w specjalnym formacie
            arg_value['_ruby_object']
          else
            # Standardowa konwersja
            case arg_type
            when :type_int, :type_float
              arg_value
            when :type_string
              arg_value.to_s
            when :type_bool
              # Handle PrimitiveValue for booleans
              if arg_value.is_a?(Utils::PrimitiveValue)
                arg_value.truthy?
              else
                arg_value == 'prawda'
              end
            when :type_null
              nil
            when :type_array
              arg_value.map { |elem| convert_to_ruby_value([elem])[0] }
            when :type_object
              if arg_value[:id]  # To jest obiekt Ruby
                get_object(arg_value[:id])
              else
                hash = {}
                arg_value.each do |k, v|
                  hash[k] = convert_to_ruby_value(v)
                end
                hash
              end
            else
              arg_value
            end
          end
        end
      end      
    
      def self.convert_result(result)
        if result.is_a?(Range) || result.is_a?(Regexp) || result.is_a?(Set)
          # Zachowaj obiekt Ruby w specjalnym formacie
          [:type_object, { '_ruby_object' => result, 'toString' => result.to_s }]
        else
          case result
          when Integer
            [:type_int, result]
          when Float
            [:type_float, result]
          when String
            [:type_string, result]
          when TrueClass, FalseClass
            [:type_bool, result ? Utils::BOOL_TRUE : Utils::BOOL_FALSE]
          when NilClass
            [:type_null, Utils::NULL_VALUE]
          when Symbol  # Dodajemy obsługę symboli
            [:type_string, result.to_s]  # Konwertujemy symbole na stringi
          when Array
            elements = []
            result.each do |elem|
              type, val = convert_result(elem)
              elements << { type: type, value: val }
            end
            [:type_array, elements]
          when Hash
            pairs = {}
            result.each do |k, v|
              type, val = convert_result(v)
              pairs[k.to_s] = { type: type, value: val }
            end
            [:type_object, pairs]
          when Time, Socket, TCPSocket, UDPSocket, BasicSocket, IO, File
            id = register_object(result)
            [:type_ruby_object, { id: id, class: result.class.name, string: result.to_s }]    
          else
            [:type_string, result.to_s]
          end
        end
      end

       # Wywołanie metody na obiekcie Ruby
      def self.call_object_method(object_id, method_name, args, file_path)
        # Pobierz obiekt z rejestru
        object = get_object(object_id)
        
        if object.nil?
          raise "Nieprawidłowy lub nieistniejący obiekt Ruby: #{object_id}"
        end
        
        # SprawdÅº, czy metoda jest dozwolona
        if FORBIDDEN_METHODS.include?(method_name)
          raise "Niedozwolona metoda: #{method_name}"
        end
        
        # Konwersja argumentów
				if args.any? { |arg| arg[:type] != :type_ruby_object || !arg[:value][:id] }
					ruby_args = convert_to_ruby_value(args)
				else
					ruby_args = args.map do |arg|
						get_object(arg[:value][:id])
					end
				end
        
				  # Specjalna obsługa dla operatorów matematycznych
				if ["+", "-", "*", "/", "**", "%", "&", "|", "^"].include?(method_name)
					# Dla operatoró∑ matematycznych potrzebujemy rozpakować argument
					if ruby_args.length == 1 && ruby_args[0].is_a?(Array)
						ruby_args = ruby_args[0][0]
					end
				end

        # wywołanie metody na obiekcie
        begin
          result = object.__send__(method_name, *ruby_args)
          converted_result = convert_result(result)
          { type: converted_result[0], value: converted_result[1] }
        rescue StandardError => e
					# arg_info = ruby_args.map { |a| "#{a.class}: #{a.inspect}" }.join(", ")
					# puts "DEBUG: Błąd przy wywołaniu #{object.class}##{method_name} z argumentami: #{arg_info}" if ENV['DEBUG']
					raise "Błąd podczas wywołania #{object.class.name}##{method_name}: #{e.message}"
        end
      end      

      # Metoda do rejestracji obiektu Ruby
      def self.register_object(object)
        id = object.object_id.to_s
        @@ruby_objects[id] = object
        id
      end
      
      # Metoda do pobierania obiektu Ruby
      def self.get_object(id)
        @@ruby_objects[id.to_s]
      end
    end
  end
end