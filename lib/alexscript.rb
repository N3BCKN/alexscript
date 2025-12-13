# frozen_string_literal: true

require 'colorize'
require 'slop'
require 'byebug'

require_relative('alexscript/core/core')
require_relative('alexscript/ast/ast')
require_relative('alexscript/utils/utils')

module AlexScript
  VERSION = '0.6.15'

  def self.start
    begin
      start_execution
    rescue Utils::AlexScriptError => e # AlexScript exceptions
      display_error(e)
    rescue StandardError => e # Ruby native exceptions translated
      alex_exception = Utils::ExceptionsTranslator.translate(e)
      display_error(alex_exception)
    rescue Exception => e # just in case
      alex_exception = Utils::ExceptionsTranslator.translate(e, "Krytyczny błąd programu")
      display_error(alex_exception, true)
    end
  end

  def self.display_error(exception, critical = false)
    error_message = if exception.is_a?(Utils::AlexScriptError)
                      # Format AlexScriptError
                      location = ""
                      location += "w linii #{exception.line}" if exception.line
                      "#{exception.alexscript_class_name}: #{exception.message} #{location}"
                    else
                      # Fallback for other exceptions
                      exception.to_s
                    end
    
    puts "#{error_message}".colorize(critical ? :red : :light_red)
    
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

    if filename&.end_with?('.as')
      begin
        source_file = File.expand_path(ARGV[0])
        source = File.read(filename)
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
