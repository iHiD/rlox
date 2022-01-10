module Lox
  class ParserError < ::RuntimeError; end

  class Parser
    def initialize(tokens)
      @tokens = tokens
      @current = 0
    end

    def parse
      expression()
    rescue ParserError
      nil
    end

    private
    attr_reader :tokens
    attr_accessor :current

    def expression
      equality()
    end

    def equality
      expr = comparison()

      while(match?(Token::BANG_EQUAL, Token::EQUAL_EQUAL)) do
        operator = previous()
        right = comparison()
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    def comparison
      expr = term()

      while(match?(Token::GREATER, Token::GREATER_EQUAL, Token::LESS, Token::LESS_EQUAL))
        operator = previous()
        right = term()
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    def term
      expr = factor()

      while(match?(Token::MINUS, Token::PLUS))
        operator = previous()
        right = term()
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    def factor
      expr = unary()

      while(match?(Token::SLASH, Token::STAR))
        operator = previous()
        right = unary()
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    def unary
      while(match?(Token::BANG, Token::MINUS))
        operator = previous()
        right = unary()
        Expr::Unary.new(operator, right)
      end

      primary()
    end

    def primary
      return Expr::Literal.new(Token::FALSE) if match?(Token::FALSE)
      return Expr::Literal.new(Token::TRUE) if match?(Token::TRUE)
      return Expr::Literal.new(Token::NIL) if match?(Token::NIL)

      return Expr::Literal.new(previous.literal) if match?(Token::NUMBER, Token::STRING)

      if match?(Token::LEFT_PAREN)
        expr = expression()
        consume(Token::RIGHT_PAREN, "Expect ')' after expression.")
        return Expr::Grouping.new(expr)
      end

      raise error(peek(), "Expect expression.")
    end

    ## Helper methods ##

    def match?(*types)
      types.each do |type|
        if check?(type)
          advance()
          return true
        end
      end

      false
    end

    def consume(type, message)
      rais error(peek(), message) unless check?(type)

      advance()
    end

    def error(token, message)
      Program.log_parse_error(token, message)

      return ParserError.new
    end

    def syncronize
      advance()

      until at_end?
        return if previous.type == Type::SEMICOLON

        case peek.type
        when Type::CLASS, Type::For, Type::FUN, Type::If, Type::Print,
          Type::RETURN, Type::VAR, Type::WHILE
          return
        end

        advance()
      end
    end

    def check?(type)
      return false if at_end?

      peek().type == type
    end

    def advance()
      self.current += 1 unless at_end?
      previous()
    end

    def at_end?
      peek.type == Token::EOF
    end

    def peek
      tokens[current]
    end

    def previous
      tokens[current - 1]
    end
  end
end
