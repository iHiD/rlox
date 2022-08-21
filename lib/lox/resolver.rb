module Lox
  class Resolver
    def initialize(interpreter)
      @interpreter = interpreter
      @scopes = []
      @current_function = :none
    end

    def resolve(stmt)
      if stmt.is_a?(Array)
        stmt.each { |s| resolve(s) }
      elsif stmt.is_a?(Stmt)
        stmt.accept(self)
      elsif stmt.is_a?(Expr)
        stmt.accept(self)
      end
    end

    private
    attr_reader :interpreter, :scopes, :current_function

    def visit_block_stmt(stmt)
      with_scope { resolve(stmt.statements) }
    end

    def visit_expression_stmt(stmt)
      resolve(stmt.expression)
    end

    def visit_function_stmt(stmt)
      declare(stmt.name)
      define(stmt.name)
      resolve_function(stmt, :function)
    end

    def resolve_function(func, type)
      enclosing_function = current_function
      current_function = type

      with_scope do
        func.params.each do |param|
          declare(param)
          define(param)
        end

        resolve(func.body)
      end

      current_function = enclosing_function
    end

    def visit_if_stmt(stmt)
      resolve(stmt.condition)
      resolve(stmt.then_branch)
      resolve(stmt.else_branch) if stmt.else_branch
    end

    def visit_print_stmt(stmt)
      resolve(stmt.expression)
    end

    def visit_return_stmt(stmt)
      Lox.log_resolver_error(stmt.keyword, "Can't return from top-level code") if current_function == :none
      resolve(stmt.value) if stmt.value
    end

    def visit_var_stmt(stmt)
      declare(stmt.name)
      resolve(stmt.initializer) if stmt.initializer
      define(stmt.name)
    end

    def visit_while_stmt(stmt)
      resolve(stmt.condition)
      resolve(stmt.body)
    end

    def visit_assign_expr(expr)
      resolve(expr.value)
      resolve_local(expr, expr.name)
    end

    def visit_binary_expr(expr)
      resolve(expr.left)
      resolve(expr.right)
    end

    def visit_call_expr(expr)
      resolve(expr.callee)
      resolve(expr.arguments)
    end

    def visit_grouping_expr(expr)
      resolve(expr.expression)
    end

    def visit_literal_expr(expr); end

    def visit_logical_expr(expr)
      resolve(expr.left)
      resolve(expr.right)
    end

    def visit_unary_expr(expr)
      resolve(expr.right)
    end

    def visit_variable_expr(expr)
      # We want a triple equals here as we're actively checking
      # whether the variable has been declared by not yet defined.
      if !scopes.empty? && current_scope[expr.name.lexeme] === false
        Lox.log_resolver_error(expr.name, "Can't read local variable in its own initializer")
      end

      resolve_local(expr, expr.name)
    end

    def resolve_local(expr, name)
      # Set through each scope (innermost first) and
      # check to see if the variable is define there.
      # When it is, resolve the expression with the distance
      # of the scope from the executing code.
      scopes.reverse.each.with_index do |scope, distance|
        if scope.key?(name.lexeme)
          interpreter.resolve(expr, distance)
          return # We're done.
        end
      end

      # If we get here, we presume we have global state
      # If we didn't have global state, we could execption
      # here and say that the variable isn't defined.
    end

    # When a variable is declared we set its name in the current
    # scope and set its value to false to indicated its not yet initialized
    def declare(name)
      return if scopes.empty?

      if current_scope.key?(name.lexeme)
        Lox.log_resolver_error(name, "Already a variable with this name in this scope")
      end

      current_scope[name.lexeme] = false
    end

    # Once the variable is initialized, we set
    # its status in the scope to be true.
    def define(name)
      return if scopes.empty?

      current_scope[name.lexeme] = true
    end

    def with_scope
      scopes << {}
      yield
      scopes.pop
    end

    def current_scope
      scopes.last
    end
  end
end
