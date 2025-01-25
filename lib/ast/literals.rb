# frozen_string_literal: true

module AST
  # Example: 42 in the expression "x = 42"
  class Int < Expr
    attr_reader :value

    def initialize(value, line)
      validate_types([value], [Integer])
      @value = value
      @line  = line
    end

    def pretty_print(level = 0)
      "#{indent(level)}Int(#{@value})"
    end
  end

  # Example: 'this is a string', "this is a string"
  class Str < Expr
    attr_reader :value

    def initialize(value, line)
      validate_types([value], [String])
      @value = value
      @line = line
    end

    def pretty_print(level = 0)
      "#{indent(level)}String(#{@value})"
    end
  end

  # Example: 3.14 in the expression "pi = 3.14"
  class Flt < Expr
    attr_reader :value

    def initialize(value, line)
      validate_types([value], [Float])
      @value = value
      @line  = line
    end

    def pretty_print(level = 0)
      "#{indent(level)}Float(#{@value})"
    end
  end

  # Example: true, false
  class Bool < Expr
    attr_reader :value

    def initialize(value, line)
      validate_bool_type(value)
      @value = value
      @line = line
    end

    def pretty_print(level = 0)
      "#{indent(level)}Bool(#{@value})"
    end
  end

  # example: nic
  class Null < Expr
    def initialize(line)
      @line = line
    end

    def pretty_print(level = 0)
      "#{indent(level)}Null"
    end
  end
end
