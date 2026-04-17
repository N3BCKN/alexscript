# frozen_string_literal: true

module AlexScript
  module AST
    # Interpolated string literal: "Cześć #{imie}, masz #{wiek} lat"
    # @parts is an array alternating between:
    #   - String (literal text fragment)
    #   - Expr (interpolated expression AST node)
    class InterpolatedString < Expr
      attr_reader :parts, :line

      def initialize(parts, line)
        @parts = parts
        @line = line
      end

      def pretty_print(level = 0)
        parts_str = @parts.map do |part|
          if part.is_a?(String)
            "#{indent(level + 1)}\"#{part}\""
          else
            part.pretty_print(level + 1)
          end
        end.join("\n")
        [
          "#{indent(level)}InterpolatedString(",
          parts_str,
          "#{indent(level)})"
        ].join("\n")
      end
    end
  end
end