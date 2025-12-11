#!/usr/bin/env ruby
# frozen_string_literal: true

USER_PWD = ENV['ALEXSCRIPT_USER_PWD'] || Dir.pwd

ALEXSCRIPT_ROOT = File.expand_path('..', __dir__) unless defined?(ALEXSCRIPT_ROOT)

# Add to load path
$LOAD_PATH.unshift("#{ALEXSCRIPT_ROOT}/lib") unless $LOAD_PATH.include?("#{ALEXSCRIPT_ROOT}/lib")

# Change to AlexScript directory (tylko jeśli nie jesteśmy tam już)
Dir.chdir(ALEXSCRIPT_ROOT) unless Dir.pwd == ALEXSCRIPT_ROOT

# Load dependencies
require 'colorize'
require 'slop'
require 'byebug' if ENV['DEBUG']

require_relative '../lib/alexscript/core/core'
require_relative '../lib/alexscript/ast/ast'
require_relative '../lib/alexscript/utils/utils'


module AlexScript
  VERSION = '0.6.15'

  def self.start
    begin
      start_execution
    rescue Utils::WyjatekPodstawowy => e
      display_error(e)
    rescue StandardError => e
      alex_exception = Utils::ExceptionsTranslator.translate(e)
      display_error(alex_exception)
    rescue Exception => e
      alex_exception = Utils::ExceptionsTranslator.translate(e, "Krytyczny błąd programu")
      display_error(alex_exception, true)
    end
  end

  def self.display_error(exception, critical = false)
    puts "🔴 #{exception}".colorize(critical ? :red : :light_red)
    exit(1)
  end

  def self.start_execution
    opts = Slop.parse do |o|
      o.bool '-f', '--full', 'run in full mode'
      o.bool '-t', '--time', 'measure time of execution'
    end

    Utils::Repl.new if ARGV.empty?

    filename = ARGV[0]

    if filename&.end_with?('.as', '.ldz')
      begin
        source_file = File.expand_path(filename, USER_PWD)
        source = File.read(source_file)
        puts "File '#{filename}' has been read successfully."
      rescue Errno::ENOENT
        raise Utils::BladZakresu.new("Plik '#{filename}' nie istnieje")
      end
    else
      source = ARGV[0]
    end

    start_time = Time.new if opts.time?

    if opts.full?
      puts '***************************************'.colorize(:white)
      puts 'SOURCE:'.colorize(:white)
      puts '***************************************'.colorize(:white)
      puts source

      puts '***************************************'.colorize(:white)
      puts 'LEXER:'.colorize(:white)
      puts '***************************************'.colorize(:white)
    end

    lexer = Core::Lexer.new(source)
    tokens = lexer.tokenize!

    if opts.full?
      lexer.tokens.each { |token| p token.print }

      puts '***************************************'.colorize(:white)
      puts 'PARSED AST:'.colorize(:white)
      puts '***************************************'.colorize(:white)
    end

    parser = Core::Parser.new(tokens)
    ast = parser.parse!

    if opts.full?
      puts ast.pretty_print unless ast.nil?

      puts '***************************************'.colorize(:white)
      puts 'INTERPRETER:'.colorize(:white)
      puts '***************************************'.colorize(:white)
    end

    interpreter = Core::Interpreter.new
    interpreter.set_current_file(source_file) if source_file
    wynik = interpreter.interpret_ast(ast)
    puts wynik if wynik

    return unless opts.time?

    end_time = Time.now
    puts "Execution time: #{end_time - start_time}s"
  end
end

AlexScript.start