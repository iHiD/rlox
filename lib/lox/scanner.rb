module Lox
  class Scanner
    def initialize(source)
      @source = source
      @tokens = []
      @start = 0
      @current = 0
      @line = 1
    end

    def scan_tokens
      while(!is_at_end?)
        start = current
        scan_token!
      end

      tokens << Token.new(Token::EOF, "", nil, line)
    end

    private 
    attr_reader :source, :tokens, :start, :current, :line

    def is_at_end?
      current >= source.length
    end

    def scan_token!
      c = advance!
    end

    def advance!
      source[current]
      @current += 1
    end
  end
end
