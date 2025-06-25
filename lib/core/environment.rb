# frozen_string_literal: true

module AlexScript
  module Core
    class Environment
      attr_reader :variables, :functions, :parent, :classes

      @@call_depth = 0
      @@max_call_depth = 600
      
      # method lookup cache for performance
      @@method_cache = {}
      @@cache_hits = 0
      @@cache_misses = 0

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
        
        # create cache key using interned strings
        cache_key = "#{class_name.to_sym}##{method_name.to_sym}".to_sym
        
        # check method cache first
        if @@method_cache.key?(cache_key)
          @@cache_hits += 1
          cached_result = @@method_cache[cache_key]
          
          # return cached result with fresh class_def reference
          if cached_result
            return {
              class_name: cached_result[:class_name],
              class_def: get_class(cached_result[:class_name]),
              method_info: cached_result[:method_info]
            }
          else
            return nil
          end
        end
        
        @@cache_misses += 1
        current_class_name = class_name
        
        while current_class_name
          class_def = get_class(current_class_name)
          break unless class_def
          
          # check instance methods - try both interned and non-interned keys
          if class_def[:instance_methods]
            method_key = intern_string(method_name)
            method_descriptor = class_def[:instance_methods][method_key] || class_def[:instance_methods][method_name]
            
            if method_descriptor
              result = {
                class_name: current_class_name,
                class_def: class_def,
                method_info: expand_method_descriptor(method_descriptor)
              }
              
              # cache the result (without class_def to avoid memory bloat)
              @@method_cache[cache_key] = {
                class_name: current_class_name,
                method_info: result[:method_info]
              }
              
              return result
            end
          end
          
          current_class_name = class_def[:parent]
        end
        
        # cache negative result
        @@method_cache[cache_key] = nil
        nil
      end

      def find_parent_method(instance, method_name)
        class_name = instance[:class_name]
        return nil unless class_name
        
        class_def = get_class(class_name)
        return nil unless class_def
        
        parent_name = class_def[:parent]
        return nil unless parent_name
        
        # create cache key for parent method lookup
        cache_key = "parent_#{class_name.to_sym}##{method_name.to_sym}".to_sym
        
        if @@method_cache.key?(cache_key)
          @@cache_hits += 1
          cached_result = @@method_cache[cache_key]
          
          if cached_result
            return {
              class_name: cached_result[:class_name],
              class_def: get_class(cached_result[:class_name]),
              method_info: cached_result[:method_info]
            }
          else
            return nil
          end
        end
        
        @@cache_misses += 1
        current_class_name = parent_name
        
        while current_class_name
          class_def = get_class(current_class_name)
          break unless class_def
          
          if class_def[:instance_methods]
            # try both interned and non-interned keys for compatibility
            method_key = intern_string(method_name)
            method_descriptor = class_def[:instance_methods][method_key] || class_def[:instance_methods][method_name]
            
            if method_descriptor
              result = {
                class_name: current_class_name,
                class_def: class_def,
                method_info: expand_method_descriptor(method_descriptor)
              }
              
              # cache the result
              @@method_cache[cache_key] = {
                class_name: current_class_name,
                method_info: result[:method_info]
              }
              
              return result
            end
          end
          
          current_class_name = class_def[:parent]
        end
        
        # cache negative result
        @@method_cache[cache_key] = nil
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
        
        # intern class name for memory efficiency
        class_name = intern_string(name)
        
        # optimize class definition storage
        optimized_class_def = {
          parent: class_def[:parent] ? intern_string(class_def[:parent]) : nil,
          is_abstract: class_def[:is_abstract] || false,
          static_vars: {},
          instance_methods: {},
          static_methods: {}
        }
        
        # process static vars with interned keys
        if class_def[:static_vars]
          class_def[:static_vars].each do |var_name, var_info|
            var_key = intern_string(var_name)
            optimized_class_def[:static_vars][var_key] = var_info
          end
        end
        
        # convert instance methods to lightweight descriptors with interned keys
        if class_def[:methods]
          class_def[:methods].each do |method_name, method_info|
            method_key = intern_string(method_name)
            optimized_class_def[:instance_methods][method_key] = create_method_descriptor(method_info)
          end
        end
        
        # convert static methods to lightweight descriptors with interned keys  
        if class_def[:static_methods]
          class_def[:static_methods].each do |method_name, method_info|
            method_key = intern_string(method_name)
            optimized_class_def[:static_methods][method_key] = create_method_descriptor(method_info)
          end
        end
        
        @classes[class_name] = optimized_class_def
        
        # clear method cache when new class is defined
        clear_method_cache_for_class(class_name)
      end

      def get_static_var(class_name, var_name)
        class_def = get_class(class_name) 
        return nil unless class_def
        
        # search in hierarchy for static variables
        current_class_def = class_def
        
        while current_class_def
          if current_class_def[:static_vars]
            # try both interned and non-interned keys for compatibility
            var_key = intern_string(var_name)
            var_result = current_class_def[:static_vars][var_key] || current_class_def[:static_vars][var_name]
            return var_result if var_result
          end
          
          parent_name = current_class_def[:parent]
          break unless parent_name
          
          current_class_def = get_class(parent_name)
        end
        
        nil
      end

      def get_static_method(class_name, method_name)
        class_def = get_class(class_name) # don't intern here, get_class handles it
        return nil unless class_def
        
        # create cache key for static method lookup
        cache_key = "static_#{class_name.to_sym}##{method_name.to_sym}".to_sym
        
        if @@method_cache.key?(cache_key)
          @@cache_hits += 1
          cached_result = @@method_cache[cache_key]
          return cached_result ? expand_method_descriptor(cached_result) : nil
        end
        
        @@cache_misses += 1
        current_class_def = class_def
        
        while current_class_def
          if current_class_def[:static_methods]
            # try both interned and non-interned keys for compatibility
            method_key = intern_string(method_name)
            method_descriptor = current_class_def[:static_methods][method_key] || current_class_def[:static_methods][method_name]
            
            if method_descriptor
              # cache the descriptor
              @@method_cache[cache_key] = method_descriptor
              return expand_method_descriptor(method_descriptor)
            end
          end
          
          parent_name = current_class_def[:parent]
          break unless parent_name
          
          current_class_def = get_class(parent_name)
        end
        
        # cache negative result
        @@method_cache[cache_key] = nil
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
        class_def = get_class(class_name) # don't intern here, get_class handles it  
        Utils.runtime_error("Nieznana klasa #{class_name}") unless class_def
        
        var_key = intern_string(var_name)
        class_def[:static_vars][var_key] = { value: value, type: type }
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
          if current.instance_variable_defined?(:@current_instance)
            instance = current.instance_variable_get(:@current_instance)
            return instance
          end
          current = current.parent
        end
        nil
      end

      def get_instance_method(class_name, method_name)
        class_def = get_class(class_name)
        return nil unless class_def
        
        # search in hierarchy for instance methods
        current_class_def = class_def
        
        while current_class_def
          if current_class_def[:instance_methods]
            # try both interned and non-interned keys for compatibility
            method_key = intern_string(method_name)
            method_descriptor = current_class_def[:instance_methods][method_key] || current_class_def[:instance_methods][method_name]
            return expand_method_descriptor(method_descriptor) if method_descriptor
          end
          
          parent_name = current_class_def[:parent]
          break unless parent_name
          
          current_class_def = get_class(parent_name)
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
        # use interned string for lookup
        class_key = intern_string(name) if name.is_a?(String)
        class_key ||= name # already interned
        
        current = self
        while current
          if current.instance_variable_defined?(:@classes) && current.instance_variable_get(:@classes)&.key?(class_key)
            return current.instance_variable_get(:@classes)[class_key]
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

      # string interning for memory efficiency
      @@string_cache = {}
      
      def intern_string(str)
        return str unless str.is_a?(String)
        @@string_cache[str] ||= str.to_sym
      end

      # method cache management
      def clear_method_cache_for_class(class_name)
        # clear cache entries that might be affected by new class definition
        @@method_cache.delete_if { |key, _| key.to_s.include?(class_name.to_s) }
      end
      
      def self.cache_stats
        total = @@cache_hits + @@cache_misses
        hit_rate = total > 0 ? (@@cache_hits.to_f / total * 100).round(2) : 0
        {
          hits: @@cache_hits,
          misses: @@cache_misses,
          hit_rate: "#{hit_rate}%",
          cache_size: @@method_cache.size
        }
      end
      
      def self.clear_cache
        @@method_cache.clear
        @@cache_hits = 0
        @@cache_misses = 0
      end

      # create lightweight method descriptor from full method info
      def create_method_descriptor(method_info)
        declaration = method_info[:declaration]
        
        {
          # essential method metadata with interned names
          name: intern_string(declaration.name),
          private: method_info[:private] || false,
          line: declaration.line,
          
          # parameter information preserved - DON'T intern param names!
          # interpreter needs original string names for variable lookup
          param_count: declaration.params.size,
          param_names: declaration.params.map(&:name), # keep as strings
          param_defaults: declaration.params.map { |p| p.has_default? ? p.default_value : nil },
          param_rest_flags: declaration.params.map(&:rest?),
          has_rest: declaration.params.any?(&:rest?),
          
          # keep reference to original AST for execution
          declaration: declaration,
          
          # CRITICAL FIX: keep reference to original environment for proper scope
          # this is needed for method execution context
          env: method_info[:env]
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
          
          # provide original env reference for proper method execution
          env: descriptor[:env] || self
        }
      end
    end
  end
end
