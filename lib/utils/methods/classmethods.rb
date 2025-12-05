# frozen_string_literal: true

module AlexScript
  module Utils
    module Methods
      class ClassMethods < BaseTypeHandler
        def initialize
          super
        end

        private

        def register_methods
          # basics
          register_method('nazwa', lambda { |class_def|
            class_def[:name] || "UnnamedClass"
          })

          register_method('typ', lambda { |class_def|
            "klasa"
          })

          register_method('rodzic', lambda { |class_def|
            class_def[:parent] || "nic"
          })

          register_method('czy_abstrakcyjna', lambda { |class_def|
            [:type_bool, class_def[:is_abstract] ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE]
          })

          # in memory ID (ruby based)
          register_method('id', lambda { |class_def|
            class_def[:name].hash.abs
          })

          # methods requiring env (injected as a first param)
          register_method('przodkowie', lambda { |class_def, env|
            # cache results in class definition
            return class_def[:_cached_ancestors] if class_def[:_cached_ancestors]
            
            ancestors = []
            current = class_def[:parent]
            while current
              ancestors << current
              parent_def = env.get_class(current)
              break unless parent_def
              current = parent_def[:parent]
            end
            
            result = alex_string_array(ancestors)
            class_def[:_cached_ancestors] = result  # cache for next call
            result
          })

          register_method('potomkowie', lambda { |class_def, env|
            class_name = class_def[:name]
            descendants = []
            
            # browse all env classes
            all_classes = env.get_all_classes || {}
            all_classes.each do |name, definition|
              if is_descendant_of?(definition, class_name, env)
                descendants << name
              end
            end
            
            alex_string_array(descendants.sort)
          })

          register_method('czy_dziedziczy_po', lambda { |class_def, env, parent_name|
            current_parent = class_def[:parent]
            
            while current_parent
              return [:type_bool, Core::Interpreter::BOOL_TRUE] if current_parent == parent_name
              parent_def = env.get_class(current_parent)
              break unless parent_def
              current_parent = parent_def[:parent]
            end

            [:type_bool, Core::Interpreter::BOOL_FALSE]
          })

          # instance methods
          register_method('metody', lambda { |class_def, env, only_own = false|
            if only_own
              alex_string_array(get_own_public_methods(class_def))
            else
              alex_string_array(get_all_public_methods(class_def, env))
            end
          })

          register_method('metody_prywatne', lambda { |class_def, only_own = false|
            if only_own
              alex_string_array(get_own_private_methods(class_def))
            else
              alex_string_array(get_all_private_methods(class_def, nil))
            end
          })

          register_method('metody_publiczne', lambda { |class_def, only_own = false|
            # Alias dla metody()
            if only_own
              alex_string_array(get_own_public_methods(class_def))
            else
              alex_string_array(get_all_public_methods(class_def, nil))
            end
          })

          register_method('metody_statyczne', lambda { |class_def, env, only_own = false|
            if only_own
              alex_string_array(get_own_static_methods(class_def, false))
            else
              alex_string_array(get_all_static_methods(class_def, env, false))
            end
          })

          register_method('metody_statyczne_prywatne', lambda { |class_def, only_own = false|
            if only_own
              alex_string_array(get_own_static_methods(class_def, true))
            else
             alex_string_array(get_all_static_methods(class_def, nil, true))
            end
          })

          register_method('zmienne_statyczne', lambda { |class_def, env, only_own = false|
            if only_own
              alex_string_array(get_own_static_vars(class_def))
            else
              alex_string_array(get_all_static_vars(class_def, env))
            end
          })

          # existance check
          register_method('ma_metode', lambda { |class_def, env, method_name|
            all_methods = get_all_public_methods(class_def, env)
            [:type_bool, all_methods.include?(method_name) ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE]
          })

          register_method('ma_metode_statyczna', lambda { |class_def, method_name|
            all_methods = get_all_static_methods(class_def, nil, false)
            [:type_bool, all_methods.include?(method_name) ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE]
          })

          register_method('ma_zmienna_statyczna', lambda { |class_def, var_name|
            all_vars = get_all_static_vars(class_def, nil)
            [:type_bool, all_vars.include?(var_name) ? Core::Interpreter::BOOL_TRUE : Core::Interpreter::BOOL_FALSE]
          })

          # detailed method info
          register_method('info_metody', lambda { |class_def, method_name|
            method_info = find_method_in_hierarchy(class_def, method_name, nil)
            
            if method_info
              alex_object({
                "nazwa" => method_name,
                "parametry" => method_info[:declaration].params.length,
                "prywatna" => method_info[:private] ? 'prawda' : 'falsz',
                "linia" => method_info[:declaration].line
              })
            else
              [:type_object, {}]
            end
          })

          register_method('napis', lambda { |class_def|
            name = class_def[:name] || "UnnamedClass"
            if class_def[:is_abstract]
              "#{name} (abstrakcyjna)" # ???
            elsif class_def[:parent]
              "#{name} < #{class_def[:parent]}"
            else
              name
            end
          })
        end

        # helper
        def get_own_public_methods(class_def)
          return [] unless class_def[:methods]
          
          ruby_arr = class_def[:methods].select { |name, info|
            !info[:private]
          }.keys.sort
          ruby_arr
        end

        def get_own_private_methods(class_def)
          return [] unless class_def[:methods]
          
          ruby_arr = class_def[:methods].select { |name, info|
            info[:private]
          }.keys.sort
          ruby_arr
        end

        def get_all_public_methods(class_def, env)
          methods = get_own_public_methods(class_def)
          
          # add methods from superior/upper classes
          if class_def[:parent] && env
            parent_def = env.get_class(class_def[:parent])
            if parent_def
              methods += get_all_public_methods(parent_def, env)
            end
          end
          
          methods.uniq.sort
        end

        def get_all_private_methods(class_def, env)
          methods = get_own_private_methods(class_def)
          
          if class_def[:parent] && env
            parent_def = env.get_class(class_def[:parent])
            if parent_def
              methods += get_all_private_methods(parent_def, env)
            end
          end
          
          methods.uniq.sort
        end

        def get_own_static_methods(class_def, private_only)
          return [] unless class_def[:static_methods]
          
          ruby_arr = class_def[:static_methods].select { |name, info|
            private_only ? info[:private] : !info[:private]
          }.keys.sort

          ruby_arr
        end

        def get_all_static_methods(class_def, env, private_only)
          methods = get_own_static_methods(class_def, private_only)
          
          if class_def[:parent] && env
            parent_def = env.get_class(class_def[:parent])
            if parent_def
              methods += get_all_static_methods(parent_def, env, private_only)
            end
          end
          
          methods.uniq.sort
        end

        def get_own_static_vars(class_def)
          return [] unless class_def[:static_vars]
          class_def[:static_vars].keys.sort
        end

        def get_all_static_vars(class_def, env)
          vars = get_own_static_vars(class_def)
          
          if class_def[:parent] && env
            parent_def = env.get_class(class_def[:parent])
            if parent_def
              vars += get_all_static_vars(parent_def, env)
            end
          end
          
          vars.uniq.sort
        end

        def find_method_in_hierarchy(class_def, method_name, env)
          # search in current class
          if class_def[:methods] && class_def[:methods][method_name]
            return class_def[:methods][method_name]
          end
          
          # search in parrent 
          if class_def[:parent] && env
            parent_def = env.get_class(class_def[:parent])
            return find_method_in_hierarchy(parent_def, method_name, env) if parent_def
          end
          
          nil
        end

        def is_descendant_of?(class_def, ancestor_name, env)
          current_parent = class_def[:parent]
          
          while current_parent
            return true if current_parent == ancestor_name
            parent_def = env.get_class(current_parent)
            break unless parent_def
            current_parent = parent_def[:parent]
          end
          
          false
        end
      end
    end
  end
end