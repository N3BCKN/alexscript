# frozen_string_literal: true

module AlexScript
  module Core
    class Environment
      include ExceptionSupport

      attr_reader :variables, :functions, :parent, :classes, :built_in_methods

      @@call_depth = 0
      @@max_call_depth = 600

      @@built_in_methods = nil

      def initialize(parent = nil)
        @variables = {}
        @parent = parent
        @functions = {}
        @classes = {}
        @modules = {}
        bootstrap_exception_classes if parent.nil? 
      end

      def built_in_methods
        @@built_in_methods ||= AlexScript::Utils::Methods::MethodRegistry.instance
      end

      def get_var(name)
        key = -name  #  intern string
        current = self
        while current
          value = current.variables[key]
          return value if value
          current = current.parent
        end
      end

      def get_class_with_hierarchy(name)
        class_def = get_class(name)
        return nil unless class_def
        
        # construct a class hierarchy
        hierarchy = {}
        current_class = name
        current_def = class_def
        
        while current_def
          hierarchy[current_class] = current_def
          parent_name = current_def[:parent]
          break unless parent_name
          
          current_class = parent_name
          current_def = get_class(parent_name)
          break unless current_def
        end
        [class_def, hierarchy]
      end

      def find_method_in_hierarchy(instance, method_name)
        return nil unless instance[:class_def]
        
        current_class_def = instance[:class_def]
        class_name = instance[:class_name]
        
        while current_class_def
          # check if method exists in current class
          if current_class_def[:methods] && current_class_def[:methods].key?(method_name)
            return {
              class_name: class_name,
              class_def: current_class_def,
              method_info: current_class_def[:methods][method_name]
            }
          end
          
          # move to parent class
          parent_name = current_class_def[:parent]
          break unless parent_name
          
          # find parent class definition
          # first try module path if instance has one
          if instance[:module_path]
            parent_class_def = get_module_class(instance[:module_path], parent_name)
            current_class_def = parent_class_def
          else
            # fallback to global classes
            current_class_def = get_class(parent_name)
          end
          
          class_name = parent_name
        end
        
        nil
      end

      # finds method in parent class
      def find_parent_method(instance, method_name)
        class_name = instance[:class_name]
        return nil unless class_name
        
        class_def = get_class(class_name)
        return nil unless class_def
        
        parent_name = class_def[:parent]
        return nil unless parent_name
        
        current_class_name = parent_name
        
        while current_class_name
          class_def = get_class(current_class_name)
          break unless class_def
          
          if class_def[:methods].key?(method_name)
            return {
              class_name: current_class_name,
              class_def: class_def,
              method_info: class_def[:methods][method_name]
            }
          end
          
          current_class_name = class_def[:parent]
        end
        
        nil  # method not found in parent class
      end

      # method to get current function/method context
      def get_current_function_context
        Utils::ContextTracker.current_method_name
      end

      # method to check if method exists in class hierarchy
      def method_exists_in_hierarchy?(instance, method_name)
        find_method_in_hierarchy(instance, method_name) != nil
      end

      # more complex method for finding method in parent class that considers:
      # 1. if we're in constructor context
      # 2. if method with same name can be found
      # 3. if given method exists in hierarchy
      def find_parent_method_by_context(instance, method_name = nil)
        class_name = instance[:class_name]
        return nil unless class_name
        
        # if no method name provided, use context
        if method_name.nil?
          current_method = Utils::ContextTracker.current_method_name
          return nil unless current_method
          method_name = current_method
        end
        
        # special handling for constructor
        if method_name == "konstruktor"
          return find_parent_method(instance, "konstruktor")
        end
        
        # find current object's class
        class_def = get_class(class_name)
        return nil unless class_def
        
        # find parent class
        parent_name = class_def[:parent]
        return nil unless parent_name
        
        # look for method in parent class
        parent_class_def = get_class(parent_name)
        return nil unless parent_class_def
        
        # check if method exists in parent class
        if parent_class_def[:methods].key?(method_name)
          return {
            class_name: parent_name,
            class_def: parent_class_def,
            method_info: parent_class_def[:methods][method_name]
          }
        end
        
        # continue searching in class hierarchy
        current_class_name = parent_name
        
        while current_class_name
          class_def = get_class(current_class_name)
          break unless class_def
          
          if class_def[:methods].key?(method_name)
            return {
              class_name: current_class_name,
              class_def: class_def,
              method_info: class_def[:methods][method_name]
            }
          end
          
          current_class_name = class_def[:parent]
        end
        
        nil
      end

      def define_class(name, class_def)
        @classes ||= {}
        
        class_def[:static_vars] ||= {}
        class_def[:static_methods] ||= {}
        
        # detect if it's a exception class
        if should_be_exception_class?(name, class_def)
          class_def[:is_exception] = true
          class_def[:is_builtin] = false
          class_def[:exception_metadata] = {
            ruby_class: determine_ruby_exception_class(name, class_def),
            created_at: Time.now.to_i
          }
          ensure_exception_has_constructor(class_def)
        else
          class_def[:is_exception] = false
        end
        
        @classes[name] = class_def
      end

      def get_static_var(class_name, var_name)
        class_def = get_class(class_name)
        return nil unless class_def && class_def[:static_vars]
        
        class_def[:static_vars][var_name]
      end

      def is_subclass_of(child_class_name, parent_class_name)
        return false unless child_class_name && parent_class_name
        return true if child_class_name == parent_class_name
        
        current_class = child_class_name
        while current_class
          class_def = get_class(current_class)
          return false unless class_def
          return true if class_def[:parent] == parent_class_name
          current_class = class_def[:parent]
        end
        
        false
      end

      def set_static_var(class_name, var_name, value, type)
        class_def = get_class(class_name)
        Utils.runtime_error("Nieznana klasa #{class_name}") unless class_def
        
        class_def[:static_vars][var_name] = { value: value, type: type }
      end

      def set_local_var(name, value, type, is_constant = false)
        @variables[name] = { value: value, type: type, constant: is_constant }
      end

      def set_instance(instance)
        @current_instance = instance
      end

      def get_instance
        current = self
        while current
          return current.instance_variable_get(:@current_instance) if current.instance_variable_defined?(:@current_instance)
          current = current.parent
        end
        nil
      end

      def set_var(name, value, type, is_constant = false)
        key = -name  #  intern string
        current = self
        while current
          if current.variables[key]
            current.variables[key][:value] = value
            return value
          end
          current = current.parent
        end
        # if var was not found in parent scopes, create it in current one
        @variables[key] = { value: value, type: type, constant: is_constant }
      end

      def get_func(name)
        key = -name
        current = self
        while current
          value = current.functions[key]
          return value if value
          current = current.parent
        end
      end
      
      def get_class(name)
        current = self
        while current
          if current.instance_variable_defined?(:@classes) && current.instance_variable_get(:@classes)&.key?(name)
            return current.instance_variable_get(:@classes)[name]
          end
          current = current.parent
        end
        nil
      end

      def get_global_env
        current = self
        current = current.parent while current.parent
        current
      end

      def load_standard_libraries
        registry = Utils::StdLibRegistry.instance
        
        # import registered classes to environment
        registry.get_all_classes.each do |class_name, class_def|
          @classes[class_name] = class_def
        end
      end

      def increment_call_depth(line)
        @@call_depth += 1
        return unless @@call_depth > @@max_call_depth

        Utils.runtime_error("Maksymalna głębokosc rekurencji (#{@@max_call_depth}) przekroczona, zbyt glebokie zagniezdzenie stosu", line)
      end

      def decrement_call_depth
        @@call_depth -= 1
      end

      # for passing function as argments to other functions
      def get_func_as_value(name)
        func = get_func(name)
        return nil unless func

        [:type_function, { declaration: func[0], env: func[1].__getobj__ }]
      end

      def set_func(name, value)
        # value is an 2dms array storing both function declaration and current env where it was declared
        @functions[-name] = value
      end

      # return a new environmnet that is a child of the current one
      # this is used for the nested scopes (functions, loop, blocks etc)
      def new_env
          child = Environment.new(self)
          child # shallow copy 
      end

      # merge env for imported files
      def merge(other_env)
        other_env.variables.each { |name, value| @variables[name] = value }
        other_env.functions.each { |name, func| @functions[name] = func }
        
        if other_env.instance_variable_defined?(:@classes)
          other_env.instance_variable_get(:@classes).each { |name, class_def| @classes[name] = class_def }
        end
      end

      def call_method(obj_type, method_name, receiver, args = [])
        method = built_in_methods.get_method(obj_type, method_name)
        Utils.runtime_error("Nieznana metoda #{method_name} dla typu #{obj_type}") unless method

        if obj_type == :type_class || obj_type == :type_instance
          # methods requiring env as a second arg
          methods_needing_env = [
            :przodkowie, :czy_dziedziczy_po, :potomkowie,
            :metody, :metody_prywatne, :metody_publiczne,
            :metody_statyczne, :metody_statyczne_prywatne,
            :zmienne_statyczne,
            :czy_instancja, :hierarchia, :czy_odpowiada, :debug_info,
            :ma_metode, :metody_statyczne, :zmienne_statyczne
          ]


          if methods_needing_env.include?(method_name.to_sym)
            method.call(receiver, self, *args)
          else
            method.call(receiver, *args)
          end
        else
          method.call(receiver, *args)
        end
      end

      def get_all_classes
        @classes || {}
      end

      def define_module(name, module_def)
        @modules ||= {}
        @modules[name] = module_def
      end

      def get_module(name)
        current = self
        while current
          if current.instance_variable_defined?(:@modules) && 
            current.instance_variable_get(:@modules)&.key?(name)
            return current.instance_variable_get(:@modules)[name]
          end
          current = current.parent
        end
        nil
      end

      # resolve path like ["Modul1", "Modul2"] to module_def
      def resolve_module_path(path)
        return nil if path.nil? || path.empty?
        
        # Initialize cache if not present
        @module_path_cache ||= {}
        
        # Check cache first (O(1))
        cache_key = -path.join("::")  # Also uses optimization #7
        return @module_path_cache[cache_key] if @module_path_cache.key?(cache_key)
        
        # cache miss - perform O(d) resolution
        module_def = get_module(path[0])
        return nil unless module_def
        
        path[1..-1].each do |name|
          return nil unless module_def[:nested_modules]
          module_def = module_def[:nested_modules][name]
          return nil unless module_def
        end
        
        # store result for future access
        @module_path_cache[cache_key] = module_def
        module_def
      end

      # get class from module
      def get_module_class(module_path, class_name)
        module_def = resolve_module_path(module_path)
        return nil unless module_def
        module_def[:classes]&.[](class_name)
      end

      # get function from module
      def get_module_function(module_path, function_name)
        module_def = resolve_module_path(module_path)
        return nil unless module_def
        module_def[:functions]&.[](function_name)
      end

      # get constant from module
      def get_module_constant(module_path, constant_name)
        module_def = resolve_module_path(module_path)
        return nil unless module_def
        module_def[:constants]&.[](constant_name)
      end
    end
  end
end
