module Lox
  class RuntimeError < ::RuntimeError
    attr_reader :token
    def initialize(token, msg)
      @token = token
      super(msg)
    end
  end

  class Interpreter
    def interpret(expr)
      value = evaluate(expr)
      puts stringify(value)
    rescue Lox::RuntimeError => e
      Program.log_runtime_error(e)
    end

    def visit_literal_expr(expr)
      expr.value
    end

    def visit_grouping_expr(expr)
      evaluate(expr.expression)
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

    private
    def evaluate(expr)
      expr.accept(self)
    end

    def truthy?(obj)
      return false if obj.nil?
      return obj if obj.is_a?(Boolean)
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
