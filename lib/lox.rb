require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

# Require all the types defined in here
# as this doesn't conform to zietwerk
require 'lox/expr'

module Lox
  def self.exec!(args)
    expression = Expr::Binary.new(
      Expr::Unary.new(
        Token.new(Token::MINUS, "-", nil, 1),
        Expr::Literal.new(123)
      ),
      Token.new(Token::STAR, "*", nil, 1),
      Expr::Grouping.new(
        Expr::Literal.new(45.67)
      )
    )
    puts Lox::AstPrinter.new.print(expression)
    # Program.exec!(args)
  end
end
