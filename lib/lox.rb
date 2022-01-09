require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

class Lox
  def self.exec!(args)
    new(args).exec!
  end

  def initialize(args)
    @args = args
  end

  def exec!
    if(args.length > 1)
      puts "Usage: lox [script]"
      exit(64)
    elsif args.length == 1
      run_file(args[0])
    else
      run_prompt
    end
  end

  private
  attr_reader :args

  def run_file(filepath)
    run(File.read(filepath))
  end

  def run_prompt
    puts "Running prompt"

    loop do
      print "> "
      line = STDIN.gets
      break unless line
      run(line)
    end
  end

  def run(source)
    scanner = Scanner.new(source)
    tokens = scanner.scan_tokens

    puts "Tokens:"
    tokens.each do |token|
      puts "token"
    end
  end
end
