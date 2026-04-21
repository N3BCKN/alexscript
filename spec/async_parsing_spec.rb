# frozen_string_literal: true

require 'spec_helper'

require_relative '../lib/alexscript/core/core'
require_relative '../lib/alexscript/ast/ast'
require_relative '../lib/alexscript/utils/utils'

RSpec.describe 'Parsing async constructs' do
  def parse(source)
    tokens = AlexScript::Core::Lexer.new(source).tokenize!
    AlexScript::Core::Parser.new(tokens).parse!
  end

  # Helper: the top-level parse result is typically a Stmts node wrapping
  # a list of top-level statements. Grab the first one.
  def first_stmt(ast)
    ast.respond_to?(:stmts) ? ast.stmts.first : ast
  end

  describe 'asynchroniczna funkcja' do
    it 'parses and sets the async flag on the FuncDclr node' do
      ast = parse("asynchroniczna funkcja f() { zwroc 1 }")
      fn  = first_stmt(ast)

      expect(fn).to be_a(AlexScript::AST::FuncDclr)
      expect(fn.name).to eq('f')
      expect(fn.async).to be true
    end

    it 'leaves the async flag false on regular funkcja' do
      ast = parse("funkcja g() { zwroc 1 }")
      fn  = first_stmt(ast)

      expect(fn).to be_a(AlexScript::AST::FuncDclr)
      expect(fn.async).to be false
    end
  end

  describe 'asynchroniczna fn (lambda)' do
    it 'parses and sets async on LambdaExpr' do
      ast = parse("niech f = asynchroniczna fn(x) { czekaj x }")
      # The top-level is a variable declaration; its right-hand side is the lambda.
      decl = first_stmt(ast)
      lam  = decl.right

      expect(lam).to be_a(AlexScript::AST::LambdaExpr)
      expect(lam.async).to be true
    end
  end

  describe 'czekaj operator' do
    it 'produces an AwaitExpr node when used inside an async function' do
      ast = parse("asynchroniczna funkcja f() { zwroc czekaj g() }")
      fn  = first_stmt(ast)
      ret = fn.body_statement.stmts.first

      expect(ret).to be_a(AlexScript::AST::ReturnStatement)
      expect(ret.value).to be_a(AlexScript::AST::AwaitExpr)
    end

    it 'raises BladSkladni when used outside an async function' do
      expect {
        parse("funkcja f() { zwroc czekaj g() }")
      }.to raise_error(AlexScript::Utils::AlexScriptError, /czekaj/)
    end

    it 'raises BladSkladni when used at top level' do
      expect {
        parse("niech x = czekaj cos()")
      }.to raise_error(AlexScript::Utils::AlexScriptError, /czekaj/)
    end

    it 'accepts nested czekaj inside a nested async scope' do
      # asynchroniczna fn inside asynchroniczna funkcja
      source = "asynchroniczna funkcja outer() { niech g = asynchroniczna fn() { czekaj cos() }; zwroc g }"
      # If parser doesn't support semicolons, fall back to newlines:
      source = <<~AS
        asynchroniczna funkcja outer() {
          niech g = asynchroniczna fn() { czekaj cos() }
          zwroc g
        }
      AS

      expect { parse(source) }.not_to raise_error
    end

    it 'does NOT leak async context outside the async function body' do
      # First define an async function (which pushes async scope), then
      # try to use czekaj AFTER it at top level. Must still fail.
      source = <<~AS
        asynchroniczna funkcja f() { zwroc 1 }
        niech y = czekaj f()
      AS

      expect {
        parse(source)
      }.to raise_error(AlexScript::Utils::AlexScriptError, /czekaj/)
    end
  end

  describe 'async methods in classes' do
    it 'parses asynchroniczna funkcja as a class method' do
      source = <<~AS
        klasa Kot {
          funkcja konstruktor() {}
          asynchroniczna funkcja mrucz() {
            czekaj uspij(10)
          }
        }
      AS
      ast = parse(source)

      expect { ast }.not_to raise_error
      # We don't drill into the exact class-body AST shape here — that's
      # implementation-specific. We just assert the whole thing parses.
    end
  end

  describe 'error messages' do
    it 'reports a clear error when asynchroniczna is followed by the wrong token' do
      expect {
        parse("asynchroniczna niech x = 5")
      }.to raise_error(AlexScript::Utils::AlexScriptError, /funkcja.*fn/)
    end
  end
end