# frozen_string_literal: true

module AlexScript
  module AST
    # ============================================================
    # AwaitExpr — czekaj WYRAZENIE
    #
    # Produced by the parser when it sees the `czekaj` keyword in
    # prefix position. Represents "suspend execution of the enclosing
    # async function until `inner` evaluates to a fulfilled promise,
    # then yield its value".
    #
    # The parser performs STATIC validation: an AwaitExpr can only
    # appear inside a function/lambda whose `async` flag is true.
    # Using `czekaj` outside an async scope raises BladSkladni at
    # parse time, not runtime — so this node will only ever reach
    # the interpreter in legal positions.
    #
    # Evaluation (wired in Message 3 of the async rollout) is the
    # interpreter's job: it resolves `inner`, extracts the underlying
    # ObietnicaImpl, and calls its #await which yields back to the
    # reactor.
    # ============================================================
    class AwaitExpr < Expr
      attr_reader :inner, :line

      def initialize(inner, line)
        validate_types([inner], [Expr])
        @inner = inner
        @line = line
      end

      def pretty_print(level = 0)
        [
          "#{indent(level)}Await(",
          @inner.pretty_print(level + 1),
          "#{indent(level)})"
        ].join("\n")
      end

      # evaluate(interpreter, env) intentionally NOT implemented here
      # yet. Falls back to AST::Node#evaluate which raises
      # NotImplementedError with a clear message. That's the correct
      # behavior at this stage: a well-formed `czekaj` parses but
      # cannot yet be executed. Wired up in Message 3.
    end
  end
end