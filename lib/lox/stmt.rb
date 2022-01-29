module Lox
  class Stmt < Struct
    def accept(visitor)
      visitor.send("visit_#{self.class.name.split("::").last.downcase}_stmt", self)
    end
  end

  Stmt::Block = Stmt.new(:statements)
  Stmt::Expression = Stmt.new(:expression)
  Stmt::Print = Stmt.new(:expression)
  Stmt::Var = Stmt.new(:name, :initializer)
end

