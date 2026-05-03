# frozen_string_literal: true


# YJIT activation 
unless ARGV.include?('--no-yjit')
  begin
    RubyVM::YJIT.enable if defined?(RubyVM::YJIT)
  rescue StandardError
    # YJIT not compiled, continue anyway
  end
end

# Suppress experimental warnings - we knowingly use IO::Buffer.
# These warnings break test output comparisons and serve no end-user purpose.
Warning[:experimental] = false if Warning.respond_to?(:[]=)

require 'colorize'
require 'slop'
# require 'byebug'

require_relative('alexscript/core/core')
require_relative('alexscript/ast/ast')
require_relative('alexscript/utils/utils')
require_relative('alexscript/native/native')
require_relative('alexscript/async/async')

module AlexScript
  VERSION = '0.9.24'

  #load standard libraries
  Native.setup!

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
                      "#{exception.alexscript_class_name}: #{exception.to_s}"
                    else
                      exception.to_s
                    end
    
    puts "#{error_message}".colorize(critical ? :red : :light_red)

    stack = extract_call_stack(exception)
    # only surface the stack when an import frame is present — keeps existing
    # error output unchanged for non-import code paths
    if stack.any? { |frame| frame[:type] == :import }
      Utils::CallStackTracker.format_stack(stack).each do |line|
        puts line.colorize(:light_black)
      end
    end

    exit(1)
  end

  def self.extract_call_stack(exception)
    if exception.respond_to?(:call_stack) && exception.call_stack
      exception.call_stack
    elsif exception.instance_variable_defined?(:@call_stack)
      exception.instance_variable_get(:@call_stack) || []
    else
      []
    end
  end

  def self.start_execution
    opts = Slop.parse do |o|
      o.bool '-v', '--version', 'print version and exit'
      o.bool '-h', '--help',    'print this help and exit'
      o.bool '-f', '--full', 'run in full mode'
      o.bool '-t', '--time', 'measure time of execution'
      o.bool '--no-yjit',    'disable YJIT (for profiling interpreter internals)'
      o.bool '--yjit-stats', 'print YJIT runtime statistics after execution'
    end

    if opts.version?
      puts "AlexScript #{AlexScript::VERSION}"
      return
    end

    if opts.help?
      puts opts
      return
    end

    # Switch to REPL when no arguments; exit cleanly when REPL loop ends.
    if ARGV.empty?
      Utils::Repl.new
      return
    end

    filename = ARGV[0]

    if filename&.end_with?('.as')
      begin
        source_file = File.expand_path(ARGV[0])
        source = File.read(filename)
        # puts "File '#{filename}' has been read successfully." # TODO: delete this
      rescue Errno::ENOENT
        raise Utils::AlexScriptError.new('BladImportu', "Plik '#{filename}' nie istnieje")
      end
    else
      source = ARGV[0]
    end

    start_time = Time.new if opts.time?

    if opts.full?
      yjit_status = (defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?) ? 'enabled' : 'disabled'
      puts '***************************************'.colorize(:white)
      puts "RUNTIME:  Ruby #{RUBY_VERSION}, YJIT #{yjit_status}".colorize(:white)
      puts '***************************************'.colorize(:white)

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

    if opts.time?
      end_time = Time.now
      puts "Execution time: #{end_time - start_time}s"
    end

    if opts.yjit_stats? && defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
      stats = RubyVM::YJIT.runtime_stats
      puts
      puts 'YJIT stats:'.colorize(:white)
      keys_of_interest = %i[
        compiled_iseq_count
        compiled_block_count
        inline_code_size
        outlined_code_size
        side_exit_count
        invalidation_count
      ]
      keys_of_interest.each do |k|
        puts "  #{k.to_s.ljust(24)} #{stats[k]}" if stats.key?(k)
      end
    end
  end
end

AlexScript.start
