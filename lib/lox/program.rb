require 'singleton'

module Lox
  class Program
    include Singleton

    def self.exec!(args)
      instance.exec!(args)
    end

    def self.log_error(*args)
      instance.log_error(*args)
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

    def log_error(line, msg)
      report(line, "", msg)
    end

    private
    attr_reader :args, :had_error

    def run_file(filepath)
      run(File.read(filepath))

      exit(65) if had_error
    end

    def run_prompt
      puts "Running prompt"

      loop do
        print "> "
        line = STDIN.gets
        break unless line

        run(line)

        @had_error = false
      end
    end

    def run(source)
      scanner = Scanner.new(source)
      tokens = scanner.scan_tokens

      puts "Tokens:"
      tokens.each do |token|
        puts token
      end
    end

    def report(line, where, message)
      puts "[line #{line}] Error #{where}: #{message}"
      @had_error = true
    end
  end
end
