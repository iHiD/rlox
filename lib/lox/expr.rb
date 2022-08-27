module Lox
  class Expr < Struct
    def accept(visitor)
      visitor.send("visit_#{self.class.name.split("::").last.downcase}_expr", self)
    end
  end

  Expr::Assign = Expr.new(:identifier, :value)
  Expr::Binary = Expr.new(:left, :operator, :right)
  Expr::Call = Expr.new(:callee, :paren, :arguments)
  Expr::Get = Expr.new(:object, :identifier)
  Expr::Grouping = Expr.new(:expression)
  Expr::Literal = Expr.new(:value)
  Expr::Ternary = Expr.new(:condition, :true_expr, :false_expr)
  Expr::Logical = Expr.new(:left, :operator, :right)
  Expr::Set = Expr.new(:object, :identifier, :value)
  Expr::This = Expr.new(:keyword)
  Expr::Unary = Expr.new(:operator, :right)
  Expr::Variable = Expr.new(:identifier)
end
