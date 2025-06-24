# frozen_string_literal: true

module AlexScript
  module Core
    class Environment
      attr_reader :variables, :functions, :parent, :classes

      @@call_depth = 0
      @@max_call_depth = 600

      def initialize(parent = nil)
        @variables = {}
        @parent = parent
        @functions = {}
        @classes = {}
      end

      def call_method(obj_type, method_name, receiver, args = [])
        if obj_type == :type_class && receiver.is_a?(String)
          begin
            registry = Utils::StdLibRegistry.instance
            return registry.execute_static_method(receiver, method_name, args)
          rescue StandardError => e
            # fallback to normal handling
          end
        end

        method = Utils::Methods::MethodRegistry.instance.get_method(obj_type, method_name)
        Utils.runtime_error("Nieznana metoda #{method_name} dla typu #{obj_type}") unless method

        method.call(receiver, *args)
      end

      def get_var(name)
        current = self
        while current
          value = current.variables[name]
          return value if value
          current = current.parent
        end
      end

      def find_method_in_hierarchy(instance, method_name)
        class_name = instance[:class_name]
        return nil unless class_name
        
        current_class_name = class_name
        
        while current_class_name
          class_def = get_class(current_class_name)
          break unless class_def
          
          # check instance methods
          if class_def[:instance_methods] && class_def[:instance_methods][method_name]
            method_descriptor = class_def[:instance_methods][method_name]
            return {
              class_name: current_class_name,
              class_def: class_def,
              method_info: expand_method_descriptor(method_descriptor)
            }
          end
          
          current_class_name = class_def[:parent]
        end
        
        nil
      end

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
          
          if class_def[:instance_methods] && class_def[:instance_methods][method_name]
            method_descriptor = class_def[:instance_methods][method_name]
            return {
              class_name: current_class_name,
              class_def: class_def,
              method_info: expand_method_descriptor(method_descriptor)
            }
          end
          
          current_class_name = class_def[:parent]
        end
        
        nil
      end

      def get_current_function_context
        Utils::ContextTracker.current_method_name
      end

      def method_exists_in_hierarchy?(instance, method_name)
        find_method_in_hierarchy(instance, method_name) != nil
      end

      def find_parent_method_by_context(instance, method_name = nil)
        class_name = instance[:class_name]
        return nil unless class_name
        
        if method_name.nil?
          current_method = Utils::ContextTracker.current_method_name
          return nil unless current_method
          method_name = current_method
        end
        
        if method_name == "konstruktor"
          return find_parent_method(instance, "konstruktor")
        end
        
        class_def = get_class(class_name)
        return nil unless class_def
        
        parent_name = class_def[:parent]
        return nil unless parent_name
        
        parent_class_def = get_class(parent_name)
        return nil unless parent_class_def
        
        if parent_class_def[:instance_methods] && parent_class_def[:instance_methods][method_name]
          method_descriptor = parent_class_def[:instance_methods][method_name]
          return {
            class_name: parent_name,
            class_def: parent_class_def,
            method_info: expand_method_descriptor(method_descriptor)
          }
        end
        
        current_class_name = parent_name
        
        while current_class_name
          class_def = get_class(current_class_name)
          break unless class_def
          
          if class_def[:instance_methods] && class_def[:instance_methods][method_name]
            method_descriptor = class_def[:instance_methods][method_name]
            return {
              class_name: current_class_name,
              class_def: class_def,
              method_info: expand_method_descriptor(method_descriptor)
            }
          end
          
          current_class_name = class_def[:parent]
        end
        
        nil
      end

      def define_class(name, class_def)
        @classes ||= {}
        
        # optimize class definition storage
        optimized_class_def = {
          parent: class_def[:parent],
          is_abstract: class_def[:is_abstract] || false,
          static_vars: class_def[:static_vars] || {},
          instance_methods: {},
          static_methods: {}
        }
        
        # convert instance methods to lightweight descriptors
        if class_def[:methods]
          class_def[:methods].each do |method_name, method_info|
            optimized_class_def[:instance_methods][method_name] = create_method_descriptor(method_info)
          end
        end
        
        # convert static methods to lightweight descriptors  
        if class_def[:static_methods]
          class_def[:static_methods].each do |method_name, method_info|
            optimized_class_def[:static_methods][method_name] = create_method_descriptor(method_info)
          end
        end
        
        @classes[name] = optimized_class_def
      end

      def get_static_var(class_name, var_name)
        class_def = get_class(class_name)
        return nil unless class_def && class_def[:static_vars]
        
        # search in hierarchy for static variables
        current_class_def = class_def
        current_class_name = class_name
        
        while current_class_def
          if current_class_def[:static_vars] && current_class_def[:static_vars][var_name]
            return current_class_def[:static_vars][var_name]
          end
          
          parent_name = current_class_def[:parent]
          break unless parent_name
          
          current_class_def = get_class(parent_name)
        end
        
        nil
      end

      def get_static_method(class_name, method_name)
        class_def = get_class(class_name)
        return nil unless class_def
        
        # search in hierarchy for static methods
        current_class_def = class_def
        
        while current_class_def
          if current_class_def[:static_methods] && current_class_def[:static_methods][method_name]
            method_descriptor = current_class_def[:static_methods][method_name]
            return expand_method_descriptor(method_descriptor)
          end
          
          parent_name = current_class_def[:parent]
          break unless parent_name
          
          current_class_def = get_class(parent_name)
        end
        
        nil
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
        current = self
        while current
          if current.variables[name]
            current.variables[name][:value] = value
            return value
          end
          current = current.parent
        end
        # if var was not found in parent scopes, create it in current one
        @variables[name] = { value: value, type: type, constant: is_constant }
      end

      def get_func(name)
        current = self
        while current
          value = current.functions[name]
          return value if value
          current = current.parent
        end
        
        # fallback: check if this is an instance method call
        current_instance = get_instance
        if current_instance
          method_result = find_method_in_hierarchy(current_instance, name)
          if method_result
            method_info = method_result[:method_info]
            # return in function format for compatibility
            return [method_info[:declaration], self] if method_info[:declaration]
          end
        end
        
        nil
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

      def get_func_as_value(name)
        func = get_func(name)
        return nil unless func

        [:type_function, { declaration: func[0], env: func[1] }]
      end

      def set_func(name, value)
        # value is an array storing both function declaration and current env where it was declared
        @functions[name] = value
      end

      def new_env
        Environment.new(self)
      end

      def merge(other_env)
        other_env.variables.each { |name, value| @variables[name] = value }
        other_env.functions.each { |name, func| @functions[name] = func }
        
        if other_env.instance_variable_defined?(:@classes)
          other_env.instance_variable_get(:@classes).each { |name, class_def| @classes[name] = class_def }
        end
      end

      private

      # create lightweight method descriptor from full method info
      def create_method_descriptor(method_info)
        declaration = method_info[:declaration]
        
        {
          # essential method metadata
          name: declaration.name,
          private: method_info[:private] || false,
          line: declaration.line,
          
          # parameter information preserved
          param_count: declaration.params.size,
          param_names: declaration.params.map(&:name),
          param_defaults: declaration.params.map { |p| p.has_default? ? p.default_value : nil },
          param_rest_flags: declaration.params.map(&:rest?),
          has_rest: declaration.params.any?(&:rest?),
          
          # keep reference to original AST for execution
          # but don't store env to avoid cycles
          declaration: declaration,
          
          # store creation environment reference but break cycle
          env_id: method_info[:env].object_id
        }
      end

      # expand method descriptor back to full method info for interpreter
      def expand_method_descriptor(descriptor)
        {
          # provide all the information interpreter needs
          declaration: descriptor[:declaration],
          private: descriptor[:private],
          name: descriptor[:name],
          line: descriptor[:line],
          
          # parameter information in interpreter-friendly format
          param_count: descriptor[:param_count],
          param_names: descriptor[:param_names],
          param_defaults: descriptor[:param_defaults], 
          param_rest_flags: descriptor[:param_rest_flags],
          has_rest: descriptor[:has_rest],
          
          # provide env reference - use current env as fallback
          env: self
        }
      end
    end
  end
end
