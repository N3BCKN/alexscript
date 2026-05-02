# frozen_string_literal: true

module AlexScript
  module AST
    # Examples: addition (x + y), multiplication (x * y), comparison (x > y)
    class BinOp < Expr
      attr_reader :left, :right, :op, :line

      def initialize(op, left, right, line)
        validate_types([op], [Utils::Token], 'operator')
        validate_types([left], [Expr], 'left operand')
        validate_types([right], [Expr], 'right operand')
        @op    = op
        @left  = left
        @right = right
        @line  = line
      end

      def evaluate(interpreter, env)
        left_type, left_value = interpreter.interpret!(@left, env)
        right_type, right_value = interpreter.interpret!(@right, env)

        # Equality with nic is identity-checked here. All other operators with nic
        # fall through to normal dispatch below, which raises a clear "unsupported
        # operator" error — Ruby/Python-style strict null handling, no silent
        # propagation that masks bugs.
        if left_type == :type_null || right_type == :type_null
          case @op.token_type
          when :tok_eq
            return [:type_bool, interpreter.to_bool_value(left_type == right_type)]
          when :tok_noteq
            return [:type_bool, interpreter.to_bool_value(left_type != right_type)]
          end
          # else: fall through to operator dispatch below
        end

        if @op.token_type == :tok_plus # addition +
          case [left_type, right_type]
          when %i[type_int type_int]
            [:type_int, left_value + right_value]
          when %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
            [:type_float, left_value.to_f + right_value.to_f]
          when %i[type_string type_array]
            [:type_string, left_value + interpreter.format_array_value(right_value).to_s]
          when %i[type_array type_string]
            [:type_string, interpreter.format_array_value(left_value).to_s + right_value]
          when %i[type_string type_object]
            [:type_string, left_value + interpreter.format_object_value(right_value).to_s]
          when %i[type_object type_string]
            [:type_string, interpreter.format_object_value(left_value).to_s + right_value]
          when %i[type_string type_string], %i[type_string type_int], %i[type_string type_float],
               %i[type_int type_string], %i[type_float type_string],
               %i[type_string type_bool], %i[type_bool type_string]
            # conversion of bool to string
            left_str = left_type == :type_bool ? (interpreter.from_bool_value(left_value) ? "prawda" : "falsz") : left_value.to_s
            right_str = right_type == :type_bool ? (interpreter.from_bool_value(right_value) ? "prawda" : "falsz") : right_value.to_s
            [:type_string, left_str + right_str]
          else
            interpreter.runtime_error(left_type, left_value, right_type, right_value, self)
          end
        elsif @op.token_type == :tok_minus # subtraction -
          case [left_type, right_type]
          when %i[type_int type_int]
            [:type_int, left_value - right_value]
          when %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
            [:type_float, left_value.to_f - right_value.to_f]
          else
            interpreter.runtime_error(left_type, left_value, right_type, right_value, self)
          end
        elsif @op.token_type == :tok_star # multiplication *
          case [left_type, right_type]
          when %i[type_int type_int]
            [:type_int, left_value * right_value]
          when %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
            [:type_float, left_value.to_f * right_value.to_f]
          else
            interpreter.runtime_error(left_type, left_value, right_type, right_value, self)
          end
        elsif @op.token_type == :tok_slash # division /
          Utils.runtime_error('Dzielenie przez zero', @op.line) if right_value == 0

          case [left_type, right_type]
          when %i[type_int type_int]
            # If both are integers but result has decimal part, convert to float
            result = left_value.to_f / right_value.to_f
            result == result.to_i ? [:type_int, result.to_i] : [:type_float, result]
          when %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
            [:type_float, left_value.to_f / right_value.to_f]
          else
            interpreter.runtime_error(left_type, left_value, right_type, right_value, self)
          end
        elsif @op.token_type == :tok_mod # modulo %
          case [left_type, right_type]
          when %i[type_int type_int]
            [:type_int, left_value % right_value]
          when %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
            [:type_float, left_value.to_f % right_value.to_f]
          else
            interpreter.runtime_error(left_type, left_value, right_type, right_value, self)
          end
        elsif @op.token_type == :tok_power # exponentiation **
          case [left_type, right_type]
          when %i[type_int type_int]
            result = left_value**right_value
            result == result.to_i ? [:type_int, result.to_i] : [:type_float, result.to_f]
          when %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
            [:type_float, left_value.to_f**right_value.to_f]
          else
            interpreter.runtime_error(left_type, left_value, right_type, right_value, self)
          end
        elsif @op.token_type == :tok_caret # bitwise XOR ^
          if left_type == :type_int && right_type == :type_int
            [:type_int, left_value ^ right_value]
          else
            interpreter.runtime_error(left_type, left_value, right_type, right_value, self)
          end
        elsif @op.token_type == :tok_greater # >
          case [left_type, right_type]
          when %i[type_int type_int], %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
            [:type_bool, interpreter.to_bool_value(left_value > right_value)]
          when %i[type_string type_string]
            [:type_bool, interpreter.to_bool_value(left_value > right_value)]
          else
            interpreter.runtime_error(left_type, left_value, right_type, right_value, self)
          end
        elsif @op.token_type == :tok_greateroreq # >=
          case [left_type, right_type]
          when %i[type_int type_int], %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
            [:type_bool, interpreter.to_bool_value(left_value >= right_value)]
          when %i[type_string type_string]
            [:type_bool, interpreter.to_bool_value(left_value >= right_value)]
          else
            interpreter.runtime_error(left_type, left_value, right_type, right_value, self)
          end
        elsif @op.token_type == :tok_smaller # 
          case [left_type, right_type]
          when %i[type_int type_int], %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
            [:type_bool, interpreter.to_bool_value(left_value < right_value)]
          when %i[type_string type_string]
            [:type_bool, interpreter.to_bool_value(left_value < right_value)]
          else
            interpreter.runtime_error(left_type, left_value, right_type, right_value, self)
          end
        elsif @op.token_type == :tok_append # << : append on arrays, left shift on integers
          if left_type == :type_array
            left_value << { type: right_type, value: right_value }
            if @left.is_a?(AST::Identifier)
              env.set_var(@left.name, left_value, left_type)
            end
            [:type_array, left_value]
          elsif left_type == :type_int && right_type == :type_int
            if right_value < 0
              Utils.runtime_error('Przesuniecie bitowe o wartosc ujemna', @op.line)
            end
            [:type_int, left_value << right_value]
          else
            interpreter.runtime_error(left_type, left_value, right_type, right_value, self)
          end
        elsif @op.token_type == :tok_rshift # >>
          if left_type == :type_int && right_type == :type_int
            if right_value < 0
              Utils.runtime_error('Przesuniecie bitowe o wartosc ujemna', @op.line)
            end
            [:type_int, left_value >> right_value]
          else
            interpreter.runtime_error(left_type, left_value, right_type, right_value, self)
          end
        elsif @op.token_type == :tok_bit_and # & bitwise AND
          if left_type == :type_int && right_type == :type_int
            [:type_int, left_value & right_value]
          else
            interpreter.runtime_error(left_type, left_value, right_type, right_value, self)
          end
        elsif @op.token_type == :tok_bit_or # | bitwise OR
          if left_type == :type_int && right_type == :type_int
            [:type_int, left_value | right_value]
          else
            interpreter.runtime_error(left_type, left_value, right_type, right_value, self)
          end
        elsif @op.token_type == :tok_smalleroreq # <=
          case [left_type, right_type]
          when %i[type_int type_int], %i[type_int type_float], %i[type_float type_int], %i[type_float type_float]
            [:type_bool, interpreter.to_bool_value(left_value <= right_value)]
          when %i[type_string type_string]
            [:type_bool, interpreter.to_bool_value(left_value <= right_value)]
          else
            interpreter.runtime_error(left_type, left_value, right_type, right_value, self)
          end
        elsif @op.token_type == :tok_eq # ==
          [:type_bool, interpreter.to_bool_value(interpreter.deep_equal?(left_type, left_value, right_type, right_value))]
        elsif @op.token_type == :tok_noteq # !=
          [:type_bool, interpreter.to_bool_value(!interpreter.deep_equal?(left_type, left_value, right_type, right_value))]
        end
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}BinaryOp(#{@op.lexeme})",
          @left.pretty_print(level + 1),
          @right.pretty_print(level + 1)
        ].join("\n")
      end
    end

    # Examples: negation (-x), logical not (!x), bitwise complement (~x)
    class UnOp < Expr
      attr_reader :op, :operand, :line

      def initialize(op, operand, line)
        validate_types([op], [Utils::Token], 'operator')
        validate_types([operand], [Expr], 'operand')
        @op      = op
        @operand = operand
        @line    = line
      end

      def evaluate(interpreter, env)
        operand_type, operand_value = interpreter.interpret!(@operand, env)

        if @op.token_type == :tok_plus
          case operand_type
          when :type_int
            [:type_int, +operand_value]
          when :type_float
            [:type_float, +operand_value]
          else
            interpreter.runtime_error_unop(operand_type, operand_value, self)
          end
        elsif @op.token_type == :tok_minus
          case operand_type
          when :type_int
            [:type_int, -operand_value]
          when :type_float
            [:type_float, -operand_value]
          else
            interpreter.runtime_error_unop(operand_type, operand_value, self)
          end
        elsif @op.token_type == :tok_not
          if operand_type == :type_bool
            [:type_bool, interpreter.to_bool_value(!interpreter.from_bool_value(operand_value))]
          elsif operand_type == :type_null
            [:type_bool, Utils::BOOL_TRUE] # !nic returns true
          else
            interpreter.runtime_error_unop(operand_type, operand_value, self)
          end
        elsif @op.token_type == :tok_tilde
          if operand_type == :type_int
            [:type_int, ~operand_value]
          else
            interpreter.runtime_error_unop(operand_type, operand_value, self)
          end
        end
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}UnaryOp(#{@op.lexeme})",
          @operand.pretty_print(level + 1)
        ].join("\n")
      end
    end

    class LogicalOp < Expr
      attr_reader :left, :right, :op, :line

      def initialize(op, left, right, line)
        validate_types([op], [Utils::Token])
        validate_types([left, right], [Expr])

        @op = op
        @left = left
        @right = right
        @line = line
      end

      # short-circut evaluation for logical operators, left 'and' is false => false, left 'or' is true => true
      # otherwise search for the right side
      def evaluate(interpreter, env)
        left_type, left_value = interpreter.interpret!(@left, env)

        if @op.token_type == :tok_or
          return [left_type, left_value] if left_value == Utils::BOOL_TRUE
        elsif @op.token_type == :tok_and
          return [left_type, left_value] if left_value == Utils::BOOL_FALSE || left_type == :type_null
        end

        return interpreter.interpret!(@right, env) unless @right.is_a?(AST::Assignment)

        # if right side is an assignment, eg: falsz i x = 10
        right_type, right_value = interpreter.interpret!(@right.right, env)
        env.set_var(@right.left.name, right_value, right_type)
        [right_type, right_value]
      end

      def pretty_print(level = 0)
        ["#{indent(level)}LogicalOp(#{@op.lexeme})",
         @left.pretty_print(level + 1),
         @right.pretty_print(level + 1)].join("\n")
      end
    end

    # Example: (1 + 2) * 3
    class Grouping < Expr
      attr_reader :value, :line

      def initialize(value, line)
        validate_types([value], [Expr], 'expression')
        @value = value
        @line  = line
      end

      def evaluate(interpreter, env)
        interpreter.interpret!(@value, env)
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}Group(",
          @value.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end
    end

    # += -= *= /=
    class CompoundAssignment < Stmt
      attr_reader :left, :operator, :right, :line

      def initialize(left, operator, right, line)
        validate_types([left], [Identifier], 'left')
        validate_types([operator], [Utils::Token], 'operator')
        validate_types([right], [Expr], 'right')
        @left = left
        @operator = operator
        @right = right
        @line = line
      end

      def evaluate(interpreter, env)
        var = env.get_var(@left.name)
        Utils.runtime_error("Niezdefiniowana zmienna #{@left.name}", @line) unless var
        Utils.runtime_error("Zmienna #{@left.name} jest stala i nie moze byc zmieniana", @line) if var[:constant]

        right_type, right_value = interpreter.interpret!(@right, env)

        # calculate new value depending on operator type
        new_value = case @operator.token_type
                    when :tok_pluseq
                      var[:value] + right_value
                    when :tok_minuseq
                      var[:value] - right_value
                    when :tok_stareq
                      var[:value] * right_value
                    when :tok_slasheq
                      Utils.runtime_error('Dzielenie przez zero', @line) if right_value == 0
                      var[:value] / right_value
                    end

        # update variable in current environment
        env.set_var(@left.name, new_value, var[:type])

        # [var[:type], new_value]
      end

      def pretty_print(level = 0)
        ["#{indent(level)}CompoundAssignment(",
         "#{indent(level + 1)}left: #{@left.pretty_print(level + 1)}",
         "#{indent(level + 1)}operator: #{@operator.lexeme}",
         "#{indent(level + 1)}right: #{@right.pretty_print(level + 1)}",
         "#{indent(level)})"].join("\n")
      end
    end

    # example: tablica.dlg
    class MethodCall < Expr
      attr_reader :object, :method_name, :arguments, :line

      def initialize(object, method_name, arguments, line)
        validate_types([object], [Expr], 'object')
        validate_types([method_name], [String], 'method_name')
        validate_types(arguments, [Expr], 'arguments') unless arguments.nil?
        @object = object
        @method_name = method_name
        @arguments = arguments || []
        @line = line
      end

      def evaluate(interpreter, env)
        interpreter.evaluate_method_call(self, env)
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}MethodCall(",
          "#{indent(level + 1)}object: #{@object.pretty_print(level + 1)}",
          "#{indent(level + 1)}method: #{@method_name}",
          "#{indent(level + 1)}arguments: #{@arguments.map { |arg| arg.pretty_print(level + 2) }.join(', ')}",
          "#{indent(level)})"
        ].join("\n")
      end
    end

    class MethodCallStmt < Stmt
      attr_reader :expression, :line

      def initialize(expression, line)
        validate_types([expression], [Expr])
        @expression = expression
        @line = line
      end

      def evaluate(interpreter, env)
        interpreter.interpret!(@expression, env)
      end

      def pretty_print(level = 0)
        ["#{indent(level)}MethodCallStmt(",
         @expression.pretty_print(level + 1),
         "#{indent(level)})"].join("\n")
      end
    end

    # ternary conditional expression: condition ? then_expr : else_expr
    # example: wiek >= 30 ? "stary" : "mlody"
    class TernaryOp < Expr
      attr_reader :condition, :then_expr, :else_expr, :line

      def initialize(condition, then_expr, else_expr, line)
        validate_types([condition, then_expr, else_expr], [Expr])
        @condition = condition
        @then_expr = then_expr
        @else_expr = else_expr
        @line = line
      end

      def evaluate(interpreter, env)
        cond_type, cond_value = interpreter.interpret!(@condition, env)
        if interpreter.is_truthy?(cond_type, cond_value, @line)
          interpreter.interpret!(@then_expr, env)
        else
          interpreter.interpret!(@else_expr, env)
        end
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}TernaryOp(",
          "#{indent(level + 1)}condition: #{@condition.pretty_print(0)}",
          "#{indent(level + 1)}then: #{@then_expr.pretty_print(0)}",
          "#{indent(level + 1)}else: #{@else_expr.pretty_print(0)}",
          "#{indent(level)})"
        ].join("\n")
      end
    end
  end
end