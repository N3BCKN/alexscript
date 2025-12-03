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
          register_method('czy_instancja', lambda { |env, instance, class_name|
            current_class = instance[:class_name]
            
            return true if current_class == class_name
            
            # check hierarchy
            class_def = env.get_class(current_class)
            return false unless class_def
            
            current_parent = class_def[:parent]
            while current_parent
              return true if current_parent == class_name
              parent_def = env.get_class(current_parent)
              break unless parent_def
              current_parent = parent_def[:parent]
            end
            
            false
          })

          register_method('metody', lambda { |env, instance|
            class_name = instance[:class_name]
            class_def = env.get_class(class_name)
            return [] unless class_def
            
            methods = get_all_instance_methods(class_def, env)
            
            # add applied instance methods
            builtin_methods = @methods.keys
            
            (methods + builtin_methods).uniq.sort
          })

          # class hierarchy
          register_method('przodkowie', lambda { |env, instance|
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
          })

          register_method('hierarchia', lambda { |env, instance|
            class_name = instance[:class_name]
            [class_name] + instance_przodkowie(env, instance)
          })

          register_method('czy_dziedziczy_po', lambda { |env, instance, parent_name|
            class_name = instance[:class_name]
            class_def = env.get_class(class_name)
            return false unless class_def
            
            current_parent = class_def[:parent]
            while current_parent
              return true if current_parent == parent_name
              parent_def = env.get_class(current_parent)
              break unless parent_def
              current_parent = parent_def[:parent]
            end
            
            false
          })

          # instance variables
          register_method('zmienne_instancji', lambda { |instance|
            return [] unless instance[:instance_vars]
            instance[:instance_vars].keys.sort
          })

          register_method('ma_zmienna_instancji', lambda { |instance, var_name|
            return false unless instance[:instance_vars]
            instance[:instance_vars].key?(var_name)
          })

          register_method('wartosc_zmiennej_instancji', lambda { |instance, var_name|
            return nil unless instance[:instance_vars]
            value = instance[:instance_vars][var_name]
            value ? value[1] : nil 
          })

          # has method?
          register_method('czy_odpowiada', lambda { |env, instance, method_name|
            class_name = instance[:class_name]
            class_def = env.get_class(class_name)
            return false unless class_def
            
            all_methods = get_all_instance_methods(class_def, env)
            builtin_methods = @methods.keys
            
            all_methods.include?(method_name) || builtin_methods.include?(method_name)
          })

          # copying 
          register_method('kopia', lambda { |instance|
            # shallow copy, only structure, without deep values
            {
              class_name: instance[:class_name],
              instance_vars: instance[:instance_vars].dup,
              class_def: instance[:class_def]
            }
          })

          # indentity comparsion
          register_method('identyczny', lambda { |instance, other|
            # is this the same object?(reference equality)
            instance.object_id == other.object_id
          })

          register_method('na_tekst', lambda { |instance|
            class_name = instance[:class_name]
            object_id_hex = instance.object_id.to_s(16)
            "#<#{class_name}:0x#{object_id_hex}>"
          })

          # Debug info
          register_method('debug_info', lambda { |env, instance|
            class_name = instance[:class_name]
            class_def = env.get_class(class_name)
            
            vars_count = instance[:instance_vars] ? instance[:instance_vars].size : 0
            methods_count = class_def ? get_all_instance_methods(class_def, env).size : 0
            
            {
              "klasa" => class_name,
              "zmienne_count" => vars_count,
              "metody_count" => methods_count,
              "object_id" => instance.object_id.to_s(16)
            }
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