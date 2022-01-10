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
      while(!at_end?)
        self.start = current
        scan_token!
      end

      tokens << Token.new(Token::EOF, "", nil, line)
    end

    private
    attr_reader :source, :tokens
    attr_accessor :start, :current, :line

    def scan_token!
      c = advance!

      case c
      when '('; add_token(Token::LEFT_PAREN)
      when ')'; add_token(Token::RIGHT_PAREN)
      when '{'; add_token(Token::LEFT_BRACE)
      when '}'; add_token(Token::RIGHT_BRACE)
      when ','; add_token(Token::COMMA)
      when '.'; add_token(Token::DOT)
      when '-'; add_token(Token::MINUS)
      when '+'; add_token(Token::PLUS)
      when ';'; add_token(Token::SEMICOLON)
      when '*'; add_token(Token::STAR)
      when '!'; add_token(advance_if_match_next!('=') ? Token::BANG_EQUAL : Token::BANG)
      when '='; add_token(advance_if_match_next!('=') ? Token::EQUAL_EQUAL : Token::EQUAL)
      when '<'; add_token(advance_if_match_next!('=') ? Token::LESS_EQUAL : Token::LESS)
      when '>'; add_token(advance_if_match_next!('=') ? Token::GREATER_EQUAL : Token::GREATER)
      when '/'
       if advance_if_match_next!('/')
         advance! while peak != "\n" && !at_end?
       else
         add_token(Token::SLASH)
       end
      when '"';      handle_string!
      when "\n";     handle_newline!
      else
        case
        when c.numeric?; handle_number!
        when c.alpha?; handle_identifier!
        when c.strip == "" # Remove whitespace
        else
          Program.log_scanner_error(line, "Unexpected character: #{c}")
        end
      end
    end

    def advance!
      source[current].tap do
        self.current += 1
      end
    end

    def peak(amount = 1)
      return nil if at_end?

      source[current + (amount - 1)]
    end

    def add_token(type, literal = nil)
      text = source[start...current]
      tokens << Token.new(type, text, literal, line)
    end

    def at_end?
      current >= source.length
    end

    def advance_if_match_next!(expected)
      return false if at_end?
      return false if source[current] != expected

      advance!
      true
    end

    def handle_newline!
      self.line += 1
    end

    def handle_string!
      while peak != '"' && !at_end?
        self.line += 1 if peak == "\n"
        advance!
      end

      if at_end?
        Program.log_scanner_error(line, "Unterminated string")
        return
      end

      advance! # The closing '"'

      add_token(Token::STRING, source[(start + 1)...(current - 1)])
    end

    def handle_number!
      advance! while peak.numeric?

      if peak == '.' && peak(2).numeric?
        advance! # Consume the .
        advance! while peak.numeric?
      end

      add_token(Token::NUMBER, source[start...current])
    end

    def handle_identifier!
      advance! while peak.alphanumeric?

      text = source[start...current]
      type = Lox::Keywords[text]

      add_token(type ? type : Token::IDENTIFIER)
    end
  end
end

class String
  def numeric?
    to_i.to_s == to_s
  end

  def alpha?
    return true if self == "_"

    ord = self.ord
    return true if ord >= 'a'.ord && ord <= 'z'.ord
    return true if ord >= "A".ord && ord <= 'Z'.ord

    false
  end

  def alphanumeric?
    alpha? || numeric?
  end
end
