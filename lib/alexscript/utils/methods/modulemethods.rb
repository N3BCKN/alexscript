# frozen_string_literal: true

module AlexScript
  module Utils
    module Methods
      # Built-in reflection methods available on any module value.
      # Methods operate on the module_def hash returned by the interpreter
      # for [:type_module, module_def] tuples.
      class ModuleMethods < BaseTypeHandler
        private

        def register_methods
          register_method('typ', ->(_mod) { 'modul' })

          register_method('nazwa', lambda { |mod|
            mod[:name] || 'UnnamedModule'
          })

          # In-memory ID (consistent with ClassMethods#id).
          register_method('id', lambda { |mod|
            (mod[:name] || '').hash.abs
          })

          # Names of constants defined directly in this module.
          register_method('stale', lambda { |mod|
            alex_string_array((mod[:constants] || {}).keys.sort)
          })

          # Names of functions defined directly in this module.
          register_method('funkcje', lambda { |mod|
            alex_string_array((mod[:functions] || {}).keys.sort)
          })

          # Names of classes defined directly in this module.
          register_method('klasy', lambda { |mod|
            alex_string_array((mod[:classes] || {}).keys.sort)
          })

          # Names of nested (inner) modules.
          register_method('podmoduly', lambda { |mod|
            alex_string_array((mod[:nested_modules] || {}).keys.sort)
          })

          # Parent module path as a string, or "nic" for top-level modules.
          register_method('modul_nadrzedny', lambda { |mod|
            parent = mod[:parent_module]
            if parent.nil? || (parent.respond_to?(:empty?) && parent.empty?)
              [:type_null, Utils::NULL_VALUE]
            else
              parent_str = parent.is_a?(Array) ? parent.join('::') : parent.to_s
              [:type_string, parent_str]
            end
          })

          # True if the module defines a constant/function/class/submodule
          # with the given name.
          register_method('zawiera', lambda { |mod, name|
            exists = (mod[:constants]       || {}).key?(name) ||
                     (mod[:functions]       || {}).key?(name) ||
                     (mod[:classes]         || {}).key?(name) ||
                     (mod[:nested_modules]  || {}).key?(name)
            [:type_bool, exists ? Utils::BOOL_TRUE : Utils::BOOL_FALSE]
          })
        end
      end
    end
  end
end