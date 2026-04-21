# frozen_string_literal: true

module AlexScript
  module Utils
    class ExceptionClassFactory
      class << self
        # ======================================================================
        # PUBLIC API
        # ======================================================================
        
        # definition of exception (WyjatekPodstawowy, BladTypu, etc.)
        def create_builtin_exception(name, parent_name, ruby_class_name)
          {
            parent: parent_name,
            body: AST::Stmts.new([], 0),
            methods: {
              'konstruktor' => {
                declaration: create_exception_constructor,
                env: nil,  # will be set by Env class
                private: false
              }
            },
            static_methods: {},
            static_vars: {},
            is_abstract: false,
            is_exception: true,
            is_builtin: true,
            exception_metadata: {
              ruby_class: ruby_class_name,
              created_at: Time.now.to_i
            }
          }
        end
        
        # returns exception hierarchy { 'NazwaWyjątku' => 'RodzicWyjątku' }
        def builtin_hierarchy
          {
            # stage 1: main categories
            'BladWykonania'          => 'WyjatekPodstawowy',
            'BladSkladni'            => 'WyjatekPodstawowy',
            'BladImportu'            => 'WyjatekPodstawowy',
            'BladLimituCzasu'        => 'WyjatekPodstawowy',
            
            # stage 2: detailed execution errors
            'BladTypu'               => 'BladWykonania',
            'BladZakresu'            => 'BladWykonania',
            'BladMetody'             => 'BladWykonania',
            'BladNazwy'              => 'BladWykonania',
            'BladArgumentu'          => 'BladWykonania',
            'BladDzieleniaPrzezZero' => 'BladWykonania'
          }
        end
        
        # AST for constructor
        # funkcja konstruktor(wiadomosc = "Błąd") {
        #   niech @wiadomosc = wiadomosc
        # }
        def create_exception_constructor
          params = [create_message_param]
          body = create_constructor_body
          
          AST::FuncDclr.new('konstruktor', params, body, 0)
        end
        
        # ======================================================================
        # PRIVATE - AST Construction Helpers
        # ======================================================================
        
        private
        
        # creates variable wiadomosc = "Błąd"
        def create_message_param
          AST::Param.new(
            'wiadomosc',              # param name
            0,                         # line (placeholder)
            AST::Str.new('Błąd', 0),  # default value
            false                      # rest param?
          )
        end
        
        # creates alexscript constructor body (niech @wiadomosc = wiadomosc)
        def create_constructor_body
          statements = [
            AST::InstanceVariableDeclaration.new(
              'wiadomosc',                           # instanca variable name
              AST::Identifier.new('wiadomosc', 0),   # param value
              0                                      # line
            )
          ]
          
          AST::Stmts.new(statements, 0)
        end
      end
    end
  end
end