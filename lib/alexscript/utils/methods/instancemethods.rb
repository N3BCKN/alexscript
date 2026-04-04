# frozen_string_literal: true

module AlexScript
  module Utils
    module Methods
      class InstanceMethods < BaseTypeHandler
        def initialize
          super
        end

        private

        def register_methods
          # basic info
          register_method('typ', lambda { |instance|
            "instancja"
          })

          register_method('klasa', lambda { |instance|
            instance[:class_name]
          })

          register_method('id', lambda { |instance|
            instance.object_id
          })

          # if instance of...
          register_method('czy_instancja', lambda { |instance, env, class_name|
            current_class = instance[:class_name]
            
            return [:type_bool, Utils::BOOL_TRUE] if current_class == class_name
            
            # check hierarchy
            class_def = env.get_class(current_class)
            return [:type_bool, Utils::BOOL_FALSE] unless class_def
            
            current_parent = class_def[:parent]
            while current_parent
              return [:type_bool, Utils::BOOL_TRUE] if current_parent == class_name
              parent_def = env.get_class(current_parent)
              break unless parent_def
              current_parent = parent_def[:parent]
            end
            
            [:type_bool, Utils::BOOL_FALSE]
          })

          register_method('metody', lambda { |instance, env|
            class_name = instance[:class_name]
            class_def = env.get_class(class_name)
            return [] unless class_def
            
            methods = get_all_instance_methods(class_def, env)
            
            # add applied instance methods
            builtin_methods = @methods.keys
            
            alex_string_array((methods + builtin_methods).uniq.sort)
          })

          # class hierarchy
          register_method('przodkowie', lambda { |instance, env|
            class_name = instance[:class_name]
            class_def = env.get_class(class_name)
            return [] unless class_def
            
            ancestors = []
            current_parent = class_def[:parent]
            
            while current_parent
              ancestors << current_parent
              parent_def = env.get_class(current_parent)
              break unless parent_def
              current_parent = parent_def[:parent]
            end
            
            alex_string_array(ancestors)
          })

          register_method('hierarchia', lambda { |instance, env|
            class_name = instance[:class_name]
            alex_string_array([class_name] + instance_przodkowie(env, instance))
          })

          register_method('czy_dziedziczy_po', lambda { |instance, env, parent_name|
            class_name = instance[:class_name]
            class_def = env.get_class(class_name)
            return [:type_bool, Utils::BOOL_FALSE] unless class_def
            
            current_parent = class_def[:parent]
            while current_parent
              return [:type_bool, Utils::BOOL_TRUE] if current_parent == parent_name
              parent_def = env.get_class(current_parent)
              break unless parent_def
              current_parent = parent_def[:parent]
            end
            
            [:type_bool, Utils::BOOL_FALSE]
          })

          # instance variables
          register_method('zmienne_instancji', lambda { |instance|
            return [] unless instance[:instance_vars]
            alex_string_array(instance[:instance_vars].keys.sort)
          })

          register_method('ma_zmienna_instancji', lambda { |instance, var_name|
            return [:type_bool, Utils::BOOL_FALSE] unless instance[:instance_vars]
            instance[:instance_vars].key?(var_name)
            [:type_bool, instance[:instance_vars].key?(var_name) ? Utils::BOOL_TRUE : Utils::BOOL_FALSE]
          })

          register_method('wartosc_zmiennej_instancji', lambda { |instance, var_name|
            return [:type_null, Utils::NULL_VALUE] unless instance[:instance_vars]
            value = instance[:instance_vars][var_name]
            value ? value[1] : [:type_null, Utils::NULL_VALUE] 
          })

          # has method?
          register_method('czy_odpowiada', lambda { |instance, env, method_name|
            class_name = instance[:class_name]
            class_def = env.get_class(class_name)
            return [:type_bool, Utils::BOOL_FALSE] unless class_def
            
            all_methods = get_all_instance_methods(class_def, env)
            builtin_methods = @methods.keys
            
            [:type_bool, (all_methods.include?(method_name) || builtin_methods.include?(method_name)) ? Utils::BOOL_TRUE : Utils::BOOL_FALSE]
          })

          # copying 
          register_method('kopia', lambda { |instance|
          # shallow copy, only structure, without deep values
            new_vars = {}
            instance[:instance_vars].each do |key, value|
              new_vars[key] = value.dup
            end
            
            copied_instance = {
              class_name: instance[:class_name],
              instance_vars: new_vars,
              class_def: instance[:class_def]
            }
            
            [:type_instance, copied_instance] 
          })

          # indentity comparsion
          register_method('identyczny', lambda { |instance, other|
            # is this the same object?(reference equality)
            [:type_bool, (instance.object_id == other.object_id) ? Utils::BOOL_TRUE : Utils::BOOL_FALSE]
          })

          register_method('napis', lambda { |instance|
            class_name = instance[:class_name]
            object_id_hex = instance.object_id.to_s(16)
            "#<#{class_name}:0x#{object_id_hex}>"
          })

          # Debug info
          register_method('debug_info', lambda { |instance, env|
            class_name = instance[:class_name]
            class_def = env.get_class(class_name)
            
            vars_count = instance[:instance_vars] ? instance[:instance_vars].size : 0
            methods_count = class_def ? get_all_instance_methods(class_def, env).size : 0
            
            alex_object({
              "klasa" => class_name,
              "zmienne_count" => vars_count,
              "metody_count" => methods_count,
              "object_id" => instance.object_id.to_s(16)
            })
          })
        end

        # helpers
        def get_all_instance_methods(class_def, env)
          methods = []
          
          # public methods from current class
          if class_def[:methods]
            methods += class_def[:methods].select { |name, info|
              !info[:private]
            }.keys
          end
          
          #  methods from ancestor classes
          if class_def[:parent]
            parent_def = env.get_class(class_def[:parent])
            if parent_def
              methods += get_all_instance_methods(parent_def, env)
            end
          end
          
          methods.uniq.sort
        end

        def instance_przodkowie(env, instance)
          class_name = instance[:class_name]
          class_def = env.get_class(class_name)
          return [] unless class_def
          
          ancestors = []
          current_parent = class_def[:parent]
          
          while current_parent
            ancestors << current_parent
            parent_def = env.get_class(current_parent)
            break unless parent_def
            current_parent = parent_def[:parent]
          end
          
          ancestors
        end
      end
    end
  end
end