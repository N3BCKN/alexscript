# frozen_string_literal: true

require 'fiber'
require 'spec_helper'

require_relative '../lib/alexscript/core/core'
require_relative '../lib/alexscript/ast/ast'
require_relative '../lib/alexscript/utils/utils'
require_relative '../lib/alexscript/native/native'
require_relative '../lib/alexscript/async/async'

RSpec.describe AlexScript::Core::AsyncInterpreter do
  let(:interpreter) { AlexScript::Core::Interpreter.new }
  let(:env)         { AlexScript::Core::Environment.new }

  # minimal promise stub — the real Obietnica class arrives in the async milestone
  let(:promise_class) do
    Class.new do
      attr_reader :state, :value, :reason
      def initialize = @state = :pending
      def rozwiaz(v)  = (@state = :resolved; @value = v)
      def odrzuc(e)   = (@state = :rejected; @reason = e)
    end
  end

  it 'resolves the promise on normal execution' do
    # parse a trivial program: niech x = 1 + 2
    ast = AlexScript::Core::Parser.new(
      AlexScript::Core::Lexer.new("niech x = 1 + 2").tokenize!
    ).parse!

    promise = promise_class.new
    described_class.interpret_in_fiber(interpreter, ast, env, promise)

    expect(promise.state).to eq(:resolved)
  end

  it 'rejects the promise instead of re-raising on AlexScript error' do
    # Reference an undeclared identifier — raises BladNazwy.
    ast = AlexScript::Core::Parser.new(
      AlexScript::Core::Lexer.new("pokazl nieistniejaca_zmienna").tokenize!
    ).parse!

    promise = promise_class.new

    expect {
      described_class.interpret_in_fiber(interpreter, ast, env, promise)
    }.not_to raise_error

    expect(promise.state).to eq(:rejected)
    expect(promise.reason).to be_a(AlexScript::Utils::AlexScriptError)
  end

  it 'swallows the error when no promise is provided' do
    ast = AlexScript::Core::Parser.new(
      AlexScript::Core::Lexer.new("pokazl nieistniejaca_zmienna").tokenize!
    ).parse!

    expect {
      described_class.interpret_in_fiber(interpreter, ast, env, nil)
    }.not_to raise_error
  end
end