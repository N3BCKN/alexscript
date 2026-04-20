# frozen_string_literal: true

module AlexScript
  module Core
    # ====================================================================
    # AsyncInterpreter — execution pathway for async fibers.
    #
    # This module is currently a SCAFFOLD. It defines the intended shape of
    # the async execution boundary but does not yet spawn fibers. It exists
    # so that:
    #   1. The structural separation between sync and async execution is
    #      in place BEFORE the async subsystem (Obietnica, czekaj,
    #      asynchroniczna) is implemented.
    #   2. The Interpreter class stays focused on tree-walking; the async
    #      concerns (fiber lifecycle, promise rejection, reactor hookup)
    #      all live here.
    #
    # The key invariant this module will enforce once wired up:
    #   An unhandled exception inside a fiber must NOT terminate the
    #   interpreter. It must be captured and transformed into a rejected
    #   Obietnica, so one buggy request in an HTTP server cannot kill
    #   the whole server.
    #
    # API sketch (to be fleshed out in the async milestone):
    #
    #   AsyncInterpreter.interpret_in_fiber(node, env, promise)
    #       Execute `node` as if it were a top-level async fiber body.
    #       On normal completion, resolve `promise` with the return value.
    #       On any exception (AlexScriptError or translated StandardError),
    #       reject `promise` with the exception — do NOT re-raise.
    #
    # For now the method is implemented as a passthrough to sync execution,
    # with the correct rescue shape already in place so that the eventual
    # Fiber.new { ... } wrapper will have one clean place to plug in.
    # ====================================================================
    module AsyncInterpreter
      module_function

      # Execute a node on behalf of an async fiber.
      #
      # `interpreter`: a Core::Interpreter instance
      # `node`:        AST node (typically the body of an asynchroniczna funkcja)
      # `env`:         Environment for execution
      # `promise`:     object responding to #rozwiaz(value) and #odrzuc(exception)
      #                (stub today, real Obietnica class in the async milestone)
      #
      # Contract:
      #   - Returns the executed node's value on success.
      #   - Translates Ruby-native StandardError into AlexScriptError before
      #     rejecting the promise (same translation policy as sync).
      #   - NEVER re-raises. The caller (fiber scheduler) must not have to
      #     guard against exceptions leaking from a fiber body.
      def interpret_in_fiber(interpreter, node, env, promise)
        result = interpreter.interpret_node_with_translation(node, env)
        promise&.rozwiaz(result) if promise.respond_to?(:rozwiaz)
        result
      rescue Utils::AlexScriptError => e
        if promise.respond_to?(:odrzuc)
          promise.odrzuc(e)
        else
          # No promise provided (e.g. detached fiber). Swallow the error
          # rather than killing the interpreter — log when a real logger
          # is wired up. For now this is the async correctness boundary.
          nil
        end
      rescue StandardError => e
        alex_error = Utils::ExceptionsTranslator.translate(e)
        if promise.respond_to?(:odrzuc)
          promise.odrzuc(alex_error)
        else
          nil
        end
      end
    end
  end
end