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

      def evaluate(interpreter, env)
        inner_type, inner_value = interpreter.interpret!(@inner, env)

        # Sugar: `czekaj` on a non-promise returns the value unchanged.
        # Lets you write code that's conditionally async without type
        # gymnastics.
        promise_impl = AlexScript::Async::PromiseValue.unwrap(inner_type, inner_value)
        return [inner_type, inner_value] if promise_impl.nil?

        # Block until the promise settles. Must be called from inside a
        # fiber running under the reactor — the parser's static validation
        # ensures `czekaj` is only ever inside an async function, and async
        # functions always execute in fibers (see evaluate_func_call async
        # path). So if we reach here without a live fiber, it's a bug.
        begin
          result = promise_impl.await
        rescue Utils::AlexScriptError => e
          # Preserve the original error; line info for `czekaj` location is
          # added upstream by ContextTracker.
          raise e
        end

        # Async fibers store tagged tuples in promise values. Unwrap if so,
        # otherwise infer the AS type from the Ruby class.
        if result.is_a?(Array) && result.size == 2 && result[0].is_a?(Symbol) && result[0].to_s.start_with?('type_')
          result
        else
          [infer_as_type(result), result]
        end
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

      private 
      # Fallback type inference for values coming out of non-fiber promises
      # (e.g. Obietnica.spelniona("hello")). Async fibers always store
      # tagged tuples, so this path only matters for user-constructed
      # fulfilled/rejected promises.
      def infer_as_type(value)
        case value
        when Integer then :type_int
        when Float then :type_float
        when String then :type_string
        when TrueClass, FalseClass then :type_bool
        when NilClass then :type_null
        when Array then :type_array
        when Hash then :type_object
        else :type_object
        end
      end
    end
  end
end