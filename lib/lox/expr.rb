module Lox
  class Expr < Struct
    def accept(visitor)
      visitor.send("visit_#{self.class.name.split("::").last.downcase}_expr", self)
    end
  end

  Expr::Assign = Expr.new(:name, :value)
  Expr::Binary = Expr.new(:left, :operator, :right)
  Expr::Grouping = Expr.new(:expression)
  Expr::If = Expr.new(:condition, :then_branch, :else_branch)
  Expr::Literal = Expr.new(:value)
  Expr::Ternary = Expr.new(:condition, :true_expr, :false_expr)
  Expr::Logical = Expr.new(:left, :operator, :right)
  Expr::Unary = Expr.new(:operator, :right)
  Expr::Variable = Expr.new(:name)
end
