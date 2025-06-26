# frozen_string_literal: true

module AlexScript
  module Utils
    module Methods
      class InstanceMethods < BaseTypeHandler
        def register_methods
          register_method('typ', ->(instance) { 'instancja' })
          
          register_method('klasa', lambda { |instance|
            instance[:class_name] || 'nieznana'
          })
          
          register_method('czy_instancja', lambda { |instance, class_name|
            is_instance = instance[:class_name] == class_name
            [:type_bool, is_instance ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE]
          })
          
          # method introspection
          register_method('metody', lambda { |instance|
            methods = []
            class_def = instance[:class_def]
            
            if class_def && class_def[:instance_methods]
              methods.concat(class_def[:instance_methods].keys.map(&:to_s))
            end
            
            # add built-in instance methods
            methods.concat(['typ', 'klasa', 'czy_instancja', 'metody', 'czy_odpowiada', 'zmienne_instancji'])
            
            methods.sort.uniq
          })
          
          register_method('zmienne_instancji', lambda { |instance|
            variables = []
            
            if instance[:instance_vars]
              variables.concat(instance[:instance_vars].keys.map(&:to_s))
            end
            
            variables.sort
          })
          
          # method existence checks
          register_method('czy_odpowiada', lambda { |instance, method_name|
            responds = false
            class_def = instance[:class_def]
            
            # check instance methods
            if class_def && class_def[:instance_methods]
              responds = class_def[:instance_methods].key?(method_name) || 
                        class_def[:instance_methods].key?(method_name.to_sym)
            end
            
            # check built-in methods
            built_in_methods = ['typ', 'klasa', 'czy_instancja', 'metody', 'czy_odpowiada', 'zmienne_instancji']
            responds ||= built_in_methods.include?(method_name)
            
            [:type_bool, responds ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE]
          })
          
          register_method('ma_zmienna_instancji', lambda { |instance, var_name|
            has_var = false
            
            if instance[:instance_vars]
              has_var = instance[:instance_vars].key?(var_name)
            end
            
            [:type_bool, has_var ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE]
          })
          
          register_method('wartosc_zmiennej_instancji', lambda { |instance, var_name|
            if instance[:instance_vars] && instance[:instance_vars][var_name]
              var_data = instance[:instance_vars][var_name]
              # return the value with its type
              var_data
            else
              [:type_null, 'nic']
            end
          })
          
          # debugging and inspection
          register_method('debug_info', lambda { |instance|
            info = {
              'klasa' => { type: :type_string, value: instance[:class_name] || 'nieznana' },
              'zmienne_count' => { type: :type_int, value: instance[:instance_vars]&.size || 0 },
              'metody_count' => { 
                type: :type_int, 
                value: instance[:class_def]&.dig(:instance_methods)&.size || 0 
              }
            }
            
            [:type_object, info]
          })
        end
      end
    end
  end
end
