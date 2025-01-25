# frozen_string_literal: true

module AST
  # "funkcja" <name> "(" <params>? ")" "{" <body_stmts> "}"
  class FuncDclr < Dclr
    attr_reader :name, :params, :body_statement

    def initialize(name, params, body_statement, line)
      validate_types([name], [String])
      validate_types(params, [Param]) unless params.nil? # TODO: dobule check this
      validate_types([body_statement], Stmts)

      @name = name
      @params = params
      @body_statement = body_statement
      @line = line
    end

    def pretty_print(level = 0)
      function_string = []
      function_string << "#{indent(level)}FunctionDeclaration("
      function_string << "#{indent(level)} name: #{@name}"

      i = 0
      while i < @params.length
        function_string << @params[i].pretty_print(level + 1)
        i += 1
      end

      function_string << @body_statement.pretty_print(level = 1)

      function_string << "#{indent(level)})"
      function_string.join("\n")
    end
  end

  # single function parameter
  class Param < Dclr
    attr_reader :name

    def initialize(name, line)
      validate_types([name], [String])
      @name = name
      @line = line
    end

    def pretty_print(level = 0)
      "#{indent(level)}Param(#{@name})"
    end
  end

  # <func_call> :== <name> "(" <args>? ")"
  # <args> :== <expr> (',' <expr>)*
  class FuncCall < Expr
    attr_reader :name, :arguments, :line

    def initialize(name, arguments, line)
      validate_types([name], [String])
      # validate_types(arguments, Array) unless arguments.nil? # TODO: dobule check this
      @name = name
      @arguments = arguments
      @line = line
    end

    def pretty_print(level = 0)
      arguments_strings = []
      arguments_strings << "#{indent(level)}FunctionCall("
      arguments_strings << "#{indent(level)} name: #{@name}"

      i = 0
      while i < @arguments.length
        arguments_strings << @arguments[i].pretty_print(level + 1)
        i += 1
      end

      arguments_strings << "#{indent(level)})"
      arguments_strings.join("\n")
    end
  end

  # a special type of statement used to wrap FuncCall expressions, eg. myfucntion()
  class FuncCallStmt < Stmt
    attr_reader :expression, :line

    def initialize(expression, line)
      validate_types([expression], [FuncCall])
      @expression = expression
      @line = line
    end

    def pretty_print(level = 0)
      ["#{indent(level)}FuncCallStmt(",
       @expression.pretty_print(level + 1)].join("\n")
    end
  end

  # "zwroc" <exprs>
  class ReturnStatement < Stmt
    attr_reader :value, :line

    def initialize(value, line)
      validate_types([value], [Expr])
      @value = value
      @line = line
    end

    def pretty_print(level = 0)
      ["#{indent(level)}Return(",
       @value.pretty_print(level + 1),
       "#{indent(level)})"].join("\n")
    end
  end
end
