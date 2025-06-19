# frozen_string_literal: true

require 'colorize'
require 'slop'
require 'byebug'

require_relative('core/core')
require_relative('ast/ast')
require_relative('utils/utils')

module AlexScript
  VERSION = '0.5.12'

  def self.start
    begin
      start_execution
    rescue Utils::WyjatekPodstawowy => e # custom exceptions 
      display_error(e)
    rescue StandardError => e # ruby native exceptions translated
      alex_exception = Utils::ExceptionsTranslator.translate(e)
      display_error(alex_exception)
    rescue Exception => e # just in case
      alex_exception = Utils::ExceptionsTranslator.translate(e, "Krytyczny błąd programu")
      display_error(alex_exception, true)
    end
  end

  def self.display_error(exception, critical = false)
    puts "🔴 #{exception}".colorize(critical ? :red : :light_red)
    
    # Display full depth of stack if its a critical error
    # if critical # && ENV['ALEX_DEBUG'] ???
    #   puts "\nStos wywołań:".colorize(:yellow)
    #   exception.backtrace&.each { |line| puts "  #{line}".colorize(:yellow) }
    # end
    
    exit(1)
  end

  def self.start_execution
    opts = Slop.parse do |o|
      o.bool '-f', '--full', 'run in full mode'
      o.bool '-t', '--time', 'measure time of execution'
    end

    # switch to REPL when no arguments
    Utils::Repl.new if ARGV.empty?

    filename = ARGV[0]

    if filename&.end_with?('.ldz')
      begin
        source_file = File.expand_path(ARGV[0])
        source = File.read(filename)
        puts "File '#{filename}' has been read successfully."
      rescue Errno::ENOENT
        raise Utils::BładZakresu.new("Plik '#{filename}' nie istnieje")
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
