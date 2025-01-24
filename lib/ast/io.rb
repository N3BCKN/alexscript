# frozen_string_literal: true

module AST
  # print value (pokaz ...)
  class PrintStmt < Stmt
    attr_reader :value, :ending

    def initialize(value, line)
      validate_types([value], Expr, 'expression')
      @value = value
      @line = line
    end

    def pretty_print(level = 0)
      [
        "#{indent(level)}PrintStatement(",
        @value.pretty_print(level + 1),
        "#{indent(level)})"
      ].join("\n")
    end
  end

  # print value with new line (pokazl ...)
  class PrintlnStmt < Stmt
    attr_reader :value, :ending

    def initialize(value, line)
      validate_types([value], Expr, 'expression')
      @value = value
      @line = line
    end

    def pretty_print(level = 0)
      [
        "#{indent(level)}PrintLineStatement(",
        @value.pretty_print(level + 1),
        "#{indent(level)})"
      ].join("\n")
    end
  end

  # wyjscie()
  class ExitStmt < Stmt
    attr_reader :code, :line

    def initialize(code, line)
      validate_types([code], Int) unless code.nil?
      @code = code
      @line = line
    end

    def pretty_print(level = 0)
      code = @code.nil? ? '' : @code.pretty_print(level + 1)

      [
        "#{indent(level)}ExitStatement(",
        code,
        "#{indent(level)})"
      ].join("\n")
    end
  end

  # eg niech x = wczytaj(...)
  class Input < Expr
    attr_reader :prompt, :line

    def initialize(prompt, line)
      validate_types([prompt], Expr, 'prompt') unless prompt.nil?
      @prompt = prompt
      @line = line
    end

    def pretty_print(level = 0)
      prompt = @prompt.nil? ? '' : @prompt.pretty_print(level + 1)

      [
        "#{indent(level)}InputStatement(",
        prompt,
        "#{indent(level)})"
      ].join("\n")
    end
  end

  # wczytaj() but only as a stmt
  class InputStmt < Stmt
    attr_reader :expression, :line

    def initialize(expression, line)
      validate_types([expression], Input)
      @expression = expression
      @line = line
    end

    def pretty_print(level = 0)
      [
        "#{indent(level)}InputStmt(",
        @expression.pretty_print(level + 1),
        "#{indent(level)})"
      ].join("\n")
    end
  end
end
