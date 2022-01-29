module Lox
  class ParserError < ::RuntimeError; end

  class Parser
    def initialize(tokens)
      @tokens = tokens
      @current = 0
    end

    def parse
      [].tap do |statements|
        until at_end?
          statements << declaration()
        end
      end
    # rescue ParserError
    #   nil
    end

    private
    attr_reader :tokens
    attr_accessor :current

    def declaration
      match?(Token::VAR) ? var_declaration : statement
    rescue ParserError
      syncronize
      nil
    end

    def var_declaration
      name = consume(Token::IDENTIFIER, "Expect variable name.")

      initializer = expression() if match?(Token::EQUAL)

      consume(Token::SEMICOLON, "Expect ';' after variable declaration")

      Stmt::Var.new(name, initializer)
    end

    def statement
      return print_statement() if match?(Token::PRINT)
      return Stmt::Block.new(block()) if match?(Token::LEFT_BRACE)

      expression_statement()
    end

    def print_statement
      value = expression()
      consume(Token::SEMICOLON, "Expect ';' after value.")

      Stmt::Print.new(value)
    end

    def expression_statement
      expr = expression()
      consume(Token::SEMICOLON, "Expect ';' after expression.")

      Stmt::Expression.new(expr)
    end

    def block
      [].tap do |statements|
        until(check?(Token::RIGHT_BRACE) || at_end?)
          statements << declaration()
        end

        consume(Token::RIGHT_BRACE, "Expect '}' after block'")
      end
    end

    def expression
      assignment()
    end

    def assignment
      expr = equality()

      if match?(Token::EQUAL)
        equals = previous()
        value = assignment()

        return Expr::Assign.new(expr.name, value) if expr.is_a?(Expr::Variable)

        error(equals, "Invalid assignment target.")
      end

      expr
    end

    def equality
      expr = ternary()

      while(match?(Token::BANG_EQUAL, Token::EQUAL_EQUAL)) do
        operator = previous()
        right = ternary()
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    def ternary
      expr = comparison()

      if match?(Token::QUESTION)
        true_expr = comparison()
        consume(Token::COLON, "Expect ':' after '?'.")
        false_expr = comparison()

        expr = Expr::Ternary.new(expr, true_expr, false_expr)
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

      return Expr::Literal.new(previous.literal.to_f) if match?(Token::NUMBER)
      return Expr::Literal.new(previous.literal) if match?(Token::STRING)

      return Expr::Variable.new(previous) if match?(Token::IDENTIFIER)

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
      raise error(peek(), message) unless check?(type)

      advance()
    end

    def error(token, message)
      Program.log_parse_error(token, message)

      return ParserError.new
    end

    def syncronize
      advance()

      until at_end?
        return if previous.type == Token::SEMICOLON

        case peek.type
        when Token::CLASS, Token::FOR, Token::FUN, Token::IF, Token::PRINT,
          Token::RETURN, Token::VAR, Token::WHILE
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
