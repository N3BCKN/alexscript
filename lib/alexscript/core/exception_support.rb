# frozen_string_literal: true

module AlexScript
  module Core
    module ExceptionSupport
      # ========================================================================
      # BOOTSTRAP - load built in exceptions
      # ========================================================================
      
      # call in Env constructor when parent.nil?
      def bootstrap_exception_classes
        # create base exception: WyjatekPodstawowy
        @classes['WyjatekPodstawowy'] = Utils::ExceptionClassFactory.create_builtin_exception(
          'WyjatekPodstawowy',
          nil,  # no parrent class 
          'Utils::WyjatekPodstawowy'
        )
        
        # set env for konstruktora
        @classes['WyjatekPodstawowy'][:methods]['konstruktor'][:env] = self
        
        # create rest of the built in exceptions
        hierarchy = Utils::ExceptionClassFactory.builtin_hierarchy
        
        hierarchy.each do |exception_name, parent_name|
          @classes[exception_name] = Utils::ExceptionClassFactory.create_builtin_exception(
            exception_name,
            parent_name,
            "Utils::#{exception_name}"
          )
          
          if @classes[exception_name][:methods]['konstruktor']
            @classes[exception_name][:methods]['konstruktor'][:env] = self
          end
        end
        
        if ENV['ALEX_DEBUG']
          puts "✓ Załadowano #{hierarchy.size + 1} klas wyjątków jako klasy"
        end
      end
      
      # ========================================================================
      # checking if created class is an exception
      # ========================================================================
      
      def is_exception_class?(class_name)
        return false unless class_name
        
        class_def = get_class(class_name)
        return false unless class_def
        
        class_def[:is_exception] == true
      end
      
      # check if defined class should be an exception, based on name, parent or metadata flag
      def should_be_exception_class?(name, class_def)
        return true if name =~ /(Blad|Błąd|Wyjatek|Wyjątek)$/i
        
        if class_def[:parent]
          parent_class = get_class(class_def[:parent])
          return true if parent_class && parent_class[:is_exception]
        end
        
        return true if class_def[:is_exception] == true
        
        false
      end
      
      # ========================================================================
      # mapping exceptions AS -> Ruby
      # ========================================================================
      
      # Find exact Ruby exception class for a given AlexScript exception
      # traverses the hierarchy upwards, looking for the closest built-in exception
      def determine_ruby_exception_class(class_name, class_def)
        if class_def[:is_builtin] && class_def[:exception_metadata]
          return class_def[:exception_metadata][:ruby_class]
        end
        
        # traverses the hierarchy upwards
        current_parent = class_def[:parent]
        
        while current_parent
          parent_def = get_class(current_parent)
          break unless parent_def
          
          # if parrent is a built in exception class, use its ruby class
          if parent_def[:is_builtin] && parent_def[:is_exception]
            return parent_def[:exception_metadata][:ruby_class]
          end
          
          current_parent = parent_def[:parent]
        end
        
        # Fallback: WyjatekPodstawowy
        'Utils::WyjatekPodstawowy'
      end
      
      # ========================================================================
      # make sure that exception class has a constructor 
      # ========================================================================
      
      # if user-defined exception has no constructor, add a default one
      def ensure_exception_has_constructor(class_def)
        class_def[:methods] ||= {}
        
        return if class_def[:methods]['konstruktor']
        
        # default constructor
        class_def[:methods]['konstruktor'] = {
          declaration: Utils::ExceptionClassFactory.create_exception_constructor,
          env: self,
          private: false
        }
      end
      
      # ========================================================================
      # hierarchy - find parrent exception class 
      # ========================================================================
      def find_exception_ancestor(class_name)
        return nil unless class_name
        
        current = class_name
        
        while current
          return current if is_exception_class?(current)
          
          class_def = get_class(current)
          break unless class_def
          
          current = class_def[:parent]
        end
        
        nil
      end
      
      # ========================================================================
      # list of all exception classes
      # ========================================================================
      
      def all_exception_classes
        @classes.select { |name, class_def| class_def[:is_exception] }.keys.sort
      end
      
      def builtin_exception_classes
        @classes.select { |name, class_def| 
          class_def[:is_exception] && class_def[:is_builtin]
        }.keys.sort
      end
      
      def user_exception_classes
        @classes.select { |name, class_def|
          class_def[:is_exception] && !class_def[:is_builtin]
        }.keys.sort
      end
    end
  end
end