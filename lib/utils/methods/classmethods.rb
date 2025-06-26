# frozen_string_literal: true

module AlexScript
  module Utils
    module Methods
      class ClassMethods < BaseTypeHandler
        def register_methods
          # basic class information
          register_method('typ', ->(class_def) { 'klasa' })
          
          register_method('nazwa', lambda { |class_def|
            class_def[:name] || 'nieznana'
          })
          
          register_method('rodzic', lambda { |class_def|
            parent = class_def[:parent]
            parent ? parent.to_s : 'nic'
          })
          
          register_method('abstrakcyjna', lambda { |class_def|
            [:type_bool, class_def[:is_abstract] ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE]
          })
          
          # method introspection
          register_method('metody', lambda { |class_def|
            methods = []
            
            # add instance methods
            if class_def[:instance_methods]
              methods.concat(class_def[:instance_methods].keys.map(&:to_s))
            end
            
            methods.sort
          })
          
          register_method('metody_statyczne', lambda { |class_def|
            methods = []
            
            # add static methods
            if class_def[:static_methods]
              methods.concat(class_def[:static_methods].keys.map(&:to_s))
            end
            
            methods.sort
          })
          
          register_method('zmienne_statyczne', lambda { |class_def|
            variables = []
            
            # add static variables
            if class_def[:static_vars]
              variables.concat(class_def[:static_vars].keys.map(&:to_s))
            end
            
            variables.sort
          })
          
          # method existence checks
          register_method('ma_metode', lambda { |class_def, method_name|
            has_method = false
            
            if class_def[:instance_methods]
              # check both string and symbol keys for compatibility
              has_method = class_def[:instance_methods].key?(method_name) || 
                          class_def[:instance_methods].key?(method_name.to_sym)
            end
            
            [:type_bool, has_method ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE]
          })
          
          register_method('ma_metode_statyczna', lambda { |class_def, method_name|
            has_method = false
            
            if class_def[:static_methods]
              # check both string and symbol keys for compatibility
              has_method = class_def[:static_methods].key?(method_name) || 
                          class_def[:static_methods].key?(method_name.to_sym)
            end
            
            [:type_bool, has_method ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE]
          })
          
          register_method('ma_zmienna_statyczna', lambda { |class_def, var_name|
            has_var = false
            
            if class_def[:static_vars]
              # check both string and symbol keys for compatibility
              has_var = class_def[:static_vars].key?(var_name) || 
                       class_def[:static_vars].key?(var_name.to_sym)
            end
            
            [:type_bool, has_var ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE]
          })
          
          # method information
          register_method('info_metody', lambda { |class_def, method_name|
            method_info = {}
            
            if class_def[:instance_methods]
              method_key = method_name.to_sym
              if class_def[:instance_methods][method_key]
                descriptor = class_def[:instance_methods][method_key]
                method_info = {
                  'nazwa' => { type: :type_string, value: method_name },
                  'prywatna' => { type: :type_bool, value: descriptor[:private] ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE },
                  'parametry' => { type: :type_int, value: descriptor[:param_count] || 0 },
                  'linia' => { type: :type_int, value: descriptor[:line] || 0 }
                }
              end
            end
            
            [:type_object, method_info]
          })
          
          # string representation
          register_method('na_string', lambda { |class_def|
            class_name = class_def[:name] || 'UnknownClass'
            abstract_marker = class_def[:is_abstract] ? ' (abstrakcyjna)' : ''
            parent_info = class_def[:parent] ? " < #{class_def[:parent]}" : ''
            "#{class_name}#{parent_info}#{abstract_marker}"
          })
        end
      end
    end
  end
end
