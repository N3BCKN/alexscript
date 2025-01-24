# frozen_string_literal: true

module AST
  # eg petla {...}
  class LoopStmt < Stmt
    attr_reader :body_statement, :line

    def initialize(body_statement, line)
      validate_types([body_statement], [Stmts])
      @body_statement = body_statement
      @line = line
    end

    def pretty_print(level = 0)
      [
        "#{indent(level)}Loop(",
        @body_statement.pretty_print(level + 1),
        "#{indent(level)})"
      ].join("\n")
    end
  end

  # eg dla niech x = 0; 10; 1 {...}
  class ForStmt < Stmt
    attr_accessor :identifier, :start_statement, :end_statement, :step_statement, :body_statement

    def initialize(identifier, start_statement, end_statement, step_statement, body_statement, line)
      validate_types([identifier], [Identifier])
      validate_types([start_statement, end_statement], [Expr])
      validate_types([step_statement], [Expr]) unless step_statement.nil?
      validate_types([body_statement], [Stmts])
      @identifier = identifier
      @start_statement = start_statement
      @end_statement = end_statement
      @step_statement = step_statement
      @body_statement = body_statement
    end

    def pretty_print(level = 0)
      step_statement = @step_statement.pretty_print(level + 1) unless @step_statement.nil?

      [
        "#{indent(level)}ForLoop(",
        @identifier.pretty_print(level + 1),
        @start_statement.pretty_print(level + 1),
        @end_statement.pretty_print(level + 1),
        step_statement,
        "#{@body_statement.pretty_print(level + 1)}",
        "#{indent(level)})"
      ].join("\n")
    end
  end

  # Example: dopoki x <= n {<body_statement>*}
  class WhileStmt < Stmt
    attr_reader :test, :body_statement, :line

    def initialize(test, body_statement, line)
      validate_types([test], [Expr])
      validate_types([body_statement], [Stmts])
      @test = test
      @body_statement = body_statement
      @line = line # dodajemy przypisanie line!
    end

    def pretty_print(level = 0)
      [
        "#{indent(level)}While(",
        @test.pretty_print(level + 1),
        @body_statement.pretty_print(level + 1),
        "#{indent(level)})"
      ].join("\n")
    end
  end

  # dla klucz, wartosc w obiekt {...}
  class ForInObjectStmt < Stmt
    attr_reader :key_identifier, :value_identifier, :object, :body_statement, :line

    def initialize(key_identifier, value_identifier, object, body_statement, line)
      validate_types([key_identifier], [Identifier], 'key identifier')
      validate_types([value_identifier], [Identifier], 'value identifier') unless value_identifier.nil?
      validate_types([object], [Expr], 'object')
      validate_types([body_statement], [Stmts], 'body')
      @key_identifier = key_identifier
      @value_identifier = value_identifier # może być nil
      @object = object
      @body_statement = body_statement
      @line = line
    end

    def pretty_print(level = 0)
      value_identifier = @value_identifier.nil? ? nil : @value_identifier.pretty_print(level + 1)

      [
        "#{indent(level)}ForInObjectLoop(",
        @key_identifier.pretty_print(level + 1),
        value_identifier,
        @object.pretty_print(level + 1),
        "#{@body_statement.pretty_print(level + 1)}",
        "#{indent(level)})"
      ].join("\n")
    end
  end

  # dla indeks w tablica {...}
  class ForInArrayStmt < Stmt
    attr_reader :element_identifier, :array, :body_statement, :line

    def initialize(element_identifier, array, body_statement, line)
      validate_types([element_identifier], [Identifier], 'element identifier')
      validate_types([array], [Expr], 'array')
      validate_types([body_statement], [Stmts], 'body')
      @element_identifier = element_identifier
      @array = array
      @body_statement = body_statement
      @line = line
    end

    def pretty_print(level = 0)
      [
        "#{indent(level)}ForInArrayLoop(",
        @element_identifier.pretty_print(level + 1),
        @array.pretty_print(level + 1),
        "#{@body_statement.pretty_print(level + 1)}",
        "#{indent(level)})"
      ].join("\n")
    end
  end

  # zakoncz (break loop)
  class BreakLoop < Stmt
    def initialize(line)
      @line = line
    end

    def pretty_print(level = 0)
      "#{indent(level)}BreakLoop()"
    end
  end

  # nastepny (next/continue loop)
  class ContinueLoop < Stmt
    def initialize(line)
      @line = line
    end

    def pretty_print(level = 0)
      "#{indent(level)}ContinueLoop()"
    end
  end
end
