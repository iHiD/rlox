module Lox
  class AstPrinter
    def print(expr)
      expr.accept(self)
    end

    def visit_binary_expr(expr)
      parenthesize(expr.operator.lexeme, expr.left, expr.right)
    end

    def visit_grouping_expr(expr)
      parenthesize("group", expr.expression)
    end

    def visit_literal_expr(expr)
      return "nil" if expr.value.nil?

      expr.value.to_s
    end

    def visit_unary_expr(expr)
      parenthesize(expr.operator.lexeme, expr.right)
    end

    private

    def parenthesize(name, *exprs)
      appends = exprs.map { |expr| " #{expr.accept(self)}" }
      "(#{name}#{appends.join})"
    end
  end
end
