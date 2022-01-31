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
      return function(:function) if match?(Token::FUN)
      return var_declaration() if match?(Token::VAR)

      statement
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
      return break_statement() if match?(Token::BREAK)
      return for_statement() if match?(Token::FOR)
      return if_statement() if match?(Token::IF)
      return print_statement() if match?(Token::PRINT)
      return while_statement() if match?(Token::WHILE)
      return Stmt::Block.new(block()) if match?(Token::LEFT_BRACE)

      expression_statement()
    end

    def break_statement
      consume(Token::SEMICOLON, "Expect ';' after break.")

      Stmt::Break.new
    end

    def for_statement
      consume(Token::LEFT_PAREN, "Expect '(' after for")

      case
      when match?(Token::SEMICOLON)
        initializer = nil
      when match?(Token::VAR)
        initializer = var_declaration()
      else
        initializer = expression_statement()
      end

      condition = check?(Token::SEMICOLON) ? Expr::Literal.new(true) : expression()
      consume(Token::SEMICOLON, "Expect ';' after loop condition")

      increment = expression() unless check?(Token::RIGHT_PAREN)
      consume(Token::RIGHT_PAREN, "Expect ')' after for clauses")

      body = statement()
      body = Stmt::Block.new([ body, Stmt::Expression.new(increment) ]) if increment

      res = Stmt::While.new(condition, body)
      initializer ? Stmt::Block.new([initializer, res]) : res
    end

    def if_statement
      consume(Token::LEFT_PAREN, "Expect '(' after if")
      condition = expression()
      consume(Token::RIGHT_PAREN, "Expect ')' after if condition")

      then_branch = statement()
      else_branch = statement() if match?(Token::ELSE)

      Stmt::If.new(condition, then_branch, else_branch)
    end

    def print_statement
      value = expression()
      consume(Token::SEMICOLON, "Expect ';' after value.")

      Stmt::Print.new(value)
    end

    def while_statement
      consume(LEFT_PAREN, "Expect '(' after while")
      condition = expression()
      consume(RIGHT_PAREN, "Expect ')' after while condition")
      body = statement()

      Stmt::While(condition, body)
    end

    def expression_statement
      expr = expression()
      consume(Token::SEMICOLON, "Expect ';' after expression.")

      Stmt::Expression.new(expr)
    end

    def function(kind)
      name = consume(Token::IDENTIFIER, "Expect #{kind} name.")
      consume(Token::LEFT_PAREN, "Expect '(' after #{kind} name")

      params = []
      unless check?(Token::RIGHT_PAREN)
        loop do
          if params.size >= 255
            error(peak(), "Can't have more than 255 params")
          end

          params << consume(Token::IDENTIFIER, "Expect paramater name")
          break unless match?(Token::COMMA)
        end
      end

      consume(Token::RIGHT_PAREN, "Expect ')' after paramaters")
      consume(Token::LEFT_BRACE, "Expect '(' after #{kind} body")

      body = block()
      Stmt::Function.new(name, params, body)
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
      expr = or_expr()

      if match?(Token::EQUAL)
        equals = previous()
        value = assignment()

        return Expr::Assign.new(expr.name, value) if expr.is_a?(Expr::Variable)

        error(equals, "Invalid assignment target.")
      end

      expr
    end

    def or_expr
      expr = and_expr()

      while(match?(Token::OR))
        operator = previous()
        right = and_expr()
        expr = Expr::Logical.new(expr, operator, right)
      end

      expr
    end

    def and_expr
      expr = equality()

      while(match?(Token::AND))
        operator = previous()
        right = and_expr()
        expr = Expr::Logical.new(expr, operator, right)
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

      call()
    end

    def finish_call(callee)
      args = []

      unless check?(Token::RIGHT_PAREN)
        loop do
          if args.size >= 255
            error(peak(), "Can't have more than 255 arguments")
          end

          args << expression()
          break unless match?(Token::COMMA)
        end
      end

      paren = consume(Token::RIGHT_PAREN, "Expect ')' after arguments")

      Expr::Call.new(callee, paren, args)
    end

    def call
      expr = primary()

      loop do
        break unless match?(Token::LEFT_PAREN)

        expr = finish_call(expr)
      end

      expr
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
