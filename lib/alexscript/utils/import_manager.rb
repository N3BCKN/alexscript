# frozen_string_literal: true

require 'set'

module AlexScript
  module Utils
    class ImportManager

      def initialize
        @imported_files = Set.new
        @current_import_stack = []
        @environments = {} # Przechowuje środowiska dla każdego pliku
      end

      def import_file(file_path, current_file = nil, parent_env = nil)
        # ── Native library fast path ──
        # Check if this is a registered native library (e.g. "czas", "mat")
        # before attempting to parse any .as files.

        if NativeClassRegistry.native_library?(file_path)
          # Use the raw name as cache key for native libs
          return @environments[file_path] if @imported_files.include?(file_path)
          env = Core::Environment.new(parent_env)
          NativeClassRegistry.load_library(file_path, env)
          @environments[file_path] = env
          @imported_files.add(file_path)
          return env
        end

        absolute_path = resolve_path(file_path, current_file)
        ContextTracker.current_file = absolute_path
        check_circular_import(absolute_path)
        return @environments[absolute_path] if @imported_files.include?(absolute_path)

        @current_import_stack.push(absolute_path)

        begin
          code = File.read(absolute_path)
          lexer = Core::Lexer.new(code)
          parser = Core::Parser.new(lexer.tokenize!)
          interpreter = Core::Interpreter.new

          env = Core::Environment.new(parent_env)
      
          interpreter.set_current_file(absolute_path)
          interpreter.interpret_ast(parser.parse!, env)

          @environments[absolute_path] = env
          @imported_files.add(absolute_path)

          env
        ensure
          @current_import_stack.pop
        end
      end

      # canonical form shown to users in traces/errors; mirrors what resolve_path
      # would actually load without exposing the absolute filesystem path
      def canonical_display_name(file_path)
        return file_path if NativeClassRegistry.native_library?(file_path)
        file_path.end_with?('.as') ? file_path : "#{file_path}.as"
      end

      private

      def resolve_path(file_path, current_file)
        normalized = file_path.end_with?('.as') ? file_path : "#{file_path}.as"
        if current_file
          current_dir = File.dirname(File.expand_path(current_file))
          File.expand_path(normalized, current_dir)
        else
          File.expand_path(normalized)
        end
      end

      def check_circular_import(absolute_path)
        return unless @current_import_stack.include?(absolute_path)

        raise "Circular import detected: #{@current_import_stack.join(' -> ')} -> #{absolute_path}"
      end
    end
  end
end
