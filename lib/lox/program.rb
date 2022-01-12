require 'singleton'

module Lox
  class Program
    include Singleton

    def self.exec!(args)
      instance.exec!(args)
    end

    def self.log_scanner_error(*args)
      instance.log_scanner_error(*args)
    end

    def self.log_parse_error(*args)
      instance.log_parse_error(*args)
    end

    def self.log_runtime_error(*args)
      instance.log_runtime_error(*args)
    end

    def initialize
      @interpreter = Interpreter.new
    end

    def exec!(args)
      if(args.length > 1)
        puts "Usage: lox [script]"
        exit(64)
      elsif args.length == 1
        run_file(args[0])
      else
        run_prompt
      end
    end

    def log_scanner_error(line, msg)
      report(line, "", msg)
    end

    def log_parse_error(token, msg)
      if token.type == Token::EOF
        report(token.line, " at end", msg)
      else
        report(token.line, " at '#{token.lexeme}'", msg)
      end
    end

    def log_runtime_error(exception)
      puts exception.message
      puts "line [#{exception.token.line}]"

      had_runtime_error = true
    end

    private
    attr_reader :interpreter
    attr_reader :args, :had_compile_error, :had_runtime_error

    def run_file(filepath)
      run(File.read(filepath))

      exit(65) if had_compile_error
      exit(70) if had_runtime_error
    end

    def run_prompt
      puts "Running prompt"

      loop do
        print "> "
        line = STDIN.gets
        break unless line

        run(line)

        @had_compile_error = false
      end
    end

    def run(source)
      scanner = Scanner.new(source)
      tokens = scanner.scan_tokens

      parser = Parser.new(tokens)
      expression = parser.parse

      return if had_compile_error

      interpreter.interpret(expression)

      # puts "Tokens:"
      # tokens.each do |token|
      #   puts token
      # end
    end

    def report(line, where, message)
      puts "[line #{line}] Error #{where}: #{message}"
      @had_compile_error = true
    end
  end
end
