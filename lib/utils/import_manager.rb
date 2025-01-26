# frozen_string_literal: true

require 'set'

module Utils
  class ImportManager
    def initialize
      @imported_files = Set.new
      @current_import_stack = []
    end

    def import_file(file_path, current_file = nil)
      # if there is a current file treat it like a relative path
      if current_file
        current_dir = File.dirname(File.expand_path(current_file))
        absolute_path = File.expand_path(file_path, current_dir)
      else
        absolute_path = File.expand_path(file_path)
      end

      if @current_import_stack.include?(absolute_path)
        raise "Circular import detected: #{@current_import_stack.join(' -> ')} -> #{file_path}"
      end

      return if @imported_files.include?(absolute_path)

      @current_import_stack.push(absolute_path)

      begin
        code = File.read(absolute_path)
        lexer = Core::Lexer.new(code)
        parser = Core::Parser.new(lexer.tokenize!)
        interpreter = Core::Interpreter.new
        interpreter.set_current_file(absolute_path)
        interpreter.interpret_ast(parser.parse!)

        @imported_files.add(absolute_path)
      rescue StandardError => e
        raise "In file #{file_path}: #{e.message}"
      ensure
        @current_import_stack.pop
      end
    end
  end
end
