# frozen_string_literal: true

module AlexScript
  module Utils
    # SourceCache reads and caches source files for the debugger.
    # Used by the 'kod' command to display lines around the current breakpoint.
    # Files are read once and stored in memory — subsequent lookups are O(1).
    class SourceCache
      @cache = {} # { absolute_path => [lines] }

      class << self
        # Returns array of lines for the given file.
        # Reads the file on first access, then serves from cache.
        # Returns nil if file cannot be read.
        def get_lines(file_path)
          return @cache[file_path] if @cache.key?(file_path)

          resolved = resolve_path(file_path)
          return nil unless resolved && File.exist?(resolved)

          begin
            lines = File.readlines(resolved, chomp: true)
            @cache[file_path] = lines
            lines
          rescue StandardError
            nil
          end
        end

        # Displays source code around the given line number.
        # current_line is 1-based (as in AlexScript source).
        # context determines how many lines above/below to show.
        # Returns formatted string ready for printing.
        def display(file_path, current_line, context: 5)
          lines = get_lines(file_path)

          unless lines
            return "  \e[90m[Nie można odczytać pliku: #{file_path}]\e[0m"
          end

          # Calculate visible range (convert to 0-based index)
          start_idx = [(current_line - 1) - context, 0].max
          end_idx = [(current_line - 1) + context, lines.size - 1].min

          output = []
          max_num_width = (end_idx + 1).to_s.length

          (start_idx..end_idx).each do |idx|
            line_num = idx + 1
            num_str = line_num.to_s.rjust(max_num_width)

            if line_num == current_line
              # Highlight current line
              output << "  \e[1;33m=> #{num_str} |\e[0m \e[1m#{lines[idx]}\e[0m"
            else
              output << "     #{num_str} \e[90m|\e[0m #{lines[idx]}"
            end
          end

          output.join("\n")
        end

        # Clears the entire cache
        def clear
          @cache.clear
        end

        private

        def resolve_path(file_path)
          return nil if file_path.nil? || file_path == 'main'

          if File.absolute_path?(file_path)
            file_path
          else
            expanded = File.expand_path(file_path)
            File.exist?(expanded) ? expanded : file_path
          end
        end
      end
    end
  end
end