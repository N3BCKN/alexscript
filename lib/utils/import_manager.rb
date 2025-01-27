# frozen_string_literal: true

require 'set'

module Utils
  class ImportManager
    def initialize
      @imported_files = Set.new
      @current_import_stack = []
      @environments = {} # Przechowuje środowiska dla każdego pliku
    end

    def import_file(file_path, current_file = nil, parent_env = nil)
      absolute_path = resolve_path(file_path, current_file)
      Utils::ContextTracker.current_file = absolute_path
      check_circular_import(absolute_path)
      return @environments[absolute_path] if @imported_files.include?(absolute_path)

      @current_import_stack.push(absolute_path)

      begin
        code = File.read(absolute_path)
        lexer = Core::Lexer.new(code)
        parser = Core::Parser.new(lexer.tokenize!)
        interpreter = Core::Interpreter.new

        env = Core::Environment.new(parent_env) # new env with parrent
        interpreter.set_current_file(absolute_path)
        interpreter.interpret_ast(parser.parse!, env)

        @environments[absolute_path] = env
        @imported_files.add(absolute_path)

        env
      ensure
        @current_import_stack.pop
      end
    end

    private

    def resolve_path(file_path, current_file)
      if current_file
        current_dir = File.dirname(File.expand_path(current_file))
        File.expand_path(file_path, current_dir)
      else
        File.expand_path(file_path)
      end
    end

    def check_circular_import(absolute_path)
      return unless @current_import_stack.include?(absolute_path)

      raise "Circular import detected: #{@current_import_stack.join(' -> ')} -> #{absolute_path}"
    end
  end
end
