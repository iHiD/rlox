module Lox
  class RuntimeError < ::RuntimeError
    attr_reader :token
    def initialize(token, msg = nil)
      @token = token
      super(msg)
    end
  end

  class BreakControlFlow < RuntimeError; end
  class ReturnControlFlow < RuntimeError
    attr_reader :value

    def initialize(value)
      super("")
      @value = value
    end
  end

  class Interpreter
    def initialize
      @globals = Environment.new(global: true)
      @locals = {}
      @environment = globals
    end

    def resolve(expr, depth)
      locals[expr] = depth
    end

    def interpret(statements)
      statements.each do |statement|
        execute(statement)
      end
    rescue Lox::RuntimeError => e
      Program.log_runtime_error(e)
    end

    def execute_block(statements, local_environment)
      previous_environment = self.environment

      begin
        self.environment = local_environment
        statements.each { |stmt| execute(stmt) }
      rescue ReturnControlFlow => e
        e.value
      ensure
        self.environment = previous_environment
      end
    end

    private
    attr_accessor :globals, :locals, :environment

    def execute(stmt)
      stmt.accept(self)
    end

    def visit_break_stmt(stmt)
      raise BreakControlFlow.new(stmt)
    end

    def visit_block_stmt(stmt)
      execute_block(stmt.statements, Environment.new(enclosing: environment))
      nil
    end

    def visit_expression_stmt(stmt)
      evaluate(stmt.expression)
      nil
    end

    def visit_function_stmt(stmt)
      function = Function.new(stmt, environment)
      environment.define(stmt.name.lexeme, function)
    end

    def visit_if_stmt(stmt)
      if truthy?(evaluate(stmt.condition))
        evaluate(stmt.then_branch)
      elsif stmt.else_branch
        evaluate(stmt.else_branch)
      end
      nil
    end

    def visit_print_stmt(stmt)
      value = evaluate(stmt.expression)
      puts value # This is actual code, not debugging
      nil
    end

    def visit_return_stmt(stmt)
      value = evaluate(stmt.value)
      raise ReturnControlFlow.new(value)
    end

    def visit_while_stmt(stmt)
      begin
        while truthy?(evaluate(stmt.condition))
          evaluate(stmt.body, breakable: true)
        end
      rescue BreakControlFlow
      end

      nil
    end

    def visit_var_stmt(stmt)
      value = evaluate(stmt.initializer) if stmt.initializer

      environment.define(stmt.name.lexeme, value)
      nil
    end

    def visit_assign_expr(expr)
      evaluate(expr.value).tap do |value|
        distance = locals[expr]
        distance ? environment.assign_at(distance, expr.name, value) : globals.assign(expr.name, value)
      end
    end

    def visit_binary_expr(expr)
      left = evaluate(expr.left)
      right = evaluate(expr.right)

      case expr.operator.type
      when Token::MINUS
        check_number_operands!(expr.operator, left, right)
        left - right
      when Token::PLUS
        if left.is_a?(Numeric)
          check_number_operands!(expr.operator, left, right)
          left + right
        elsif left.is_a?(String)
          check_string_operands!(expr.operator, left, right)
          left + right
        end
      when Token::SLASH
        check_number_operands!(expr.operator, left, right)
        left / right
      when Token::STAR
        check_number_operands!(expr.operator, left, right)
        left * right
      when Token::GREATER
        check_number_operands!(expr.operator, left, right)
        left > right
      when Token::GREATER_EQUAL
        check_number_operands!(expr.operator, left, right)
        left >= right
      when Token::LESS
        check_number_operands!(expr.operator, left, right)
        left < right
      when Token::LESS_EQUAL
        check_number_operands!(expr.operator, left, right)
        left <= right
      when Token::BANG_EQUAL
        equal(left, right)
      when Token::EQUAL_EQUAL
        equal(left, right)
      else
        nil
      end
    end

    def visit_call_expr(expr)
      callee = evaluate(expr.callee)
      args = expr.arguments.map { |arg| evaluate(arg) }

      unless callee.class < Callable
        raise RuntimeError.new(expr.paren, "Can only call functions and classes")
      end

      unless args.size == callee.arity
        raise RuntimeError.new(expr.paren, "Expected #{callee.arity} arguments but got #{args.size}.")
      end

      callee.call(self, args)
    end

    def visit_literal_expr(expr)
      expr.value
    end

    def visit_logical_expr(expr)
      left = evaluate(expr.left)

      # Early return if we don't need the RHS
      if expr.operator.type == Token::OR
        return left if truthy?(left)
      else
        return left unless truthy?(left)
      end

      evaluate(expr.right)
    end

    def visit_grouping_expr(expr)
      evaluate(expr.expression)
    end

    def visit_ternary_expr(expr)
      if truthy?(evaluate(expr.condition))
        evaluate(expr.true_expr)
      else
        evaluate(expr.false_expr)
      end
    end

    def visit_unary_expr(expr)
      right = evaluate(expr.right)

      case expr.operator.type
      when Token::MINUS
        check_number_operand!(expr.operator, right)
        0 - right
      when Token::BANG
        !(truthy?(right))
      else
        nil
      end
    end

    def visit_variable_expr(expr)
      distance = locals[expr]
      distance ? environment.get_at(distance, expr.name.lexeme) : globals.get(expr.name)
    end

    def evaluate(expr, breakable: false)
      expr.accept(self)
    end

    def truthy?(obj)
      # This is pretty horrible
      return true if obj == :true
      return false if obj == :false

      return false if obj.nil?
      return obj if obj.is_a?(TrueClass) || obj.is_a?(FalseClass)
      obj
    end

    def equal(a, b)
      return true if a.nil? && b.nil?
      return false if a.nil?

      a == b
    end

    %i[number string].each do |type|
      define_method "check_#{type}_operands!" do |operator, *objs|
        objs.each do |obj|
          send("check_#{type}_operand!", operator, obj)
        end
      rescue Lox::RuntimeError
        raise Lox::RuntimeError.new(operator, "Both operands must be #{type}s")
      end
    end

    def check_number_operand!(operator, obj)
      return if obj.is_a?(Numeric)

      raise Lox::RuntimeError.new(operator, "Operand must be a number")
    end

    def check_string_operand!(operator, obj)
      return if obj.is_a?(String)

      raise Lox::RuntimeError.new(operator, "Operand must be a string")
    end

    def stringify(obj)
      return "nil" if obj.nil?

      if obj.is_a?(Numeric)
        text = obj.to_s
        return text.split('.').first if text.end_with?(".0")
      end

      obj.to_s
    end
  end
end
