module Lox
  class Stmt < Struct
    def accept(visitor)
      visitor.send("visit_#{self.class.name.split("::").last.downcase}_stmt", self)
    end
  end

  class SimpleStmt
    def accept(visitor)
      visitor.send("visit_#{self.class.name.split("::").last.downcase}_stmt", self)
    end
  end

  class Stmt::Break < SimpleStmt; end

  Stmt::Block = Stmt.new(:statements)
  Stmt::Expression = Stmt.new(:expression)
  Stmt::Function = Stmt.new(:name, :params, :body)
  Stmt::If = Stmt.new(:condition, :then_branch, :else_branch)
  Stmt::For = Stmt.new(:condition, :body)
  Stmt::Print = Stmt.new(:expression)
  Stmt::Var = Stmt.new(:name, :initializer)
  Stmt::While = Stmt.new(:condition, :body)
end

