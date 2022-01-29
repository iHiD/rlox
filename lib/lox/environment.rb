module Lox
  class Environment
    def initialize(enclosing: nil)
      @values = {}
      @enclosing = enclosing
    end

    def define(name, value)
      values[name.lexeme] = value
    end

    def assign(name, value)
      if values.key?(name.lexeme)
        values[name.lexeme] = value
        return
      end

      return enclosing.assign(name, value) if enclosing

      guard_undefined!(name)
    end

    def get(name)
      return values[name.lexeme] if values.key?(name.lexeme)
      return enclosing.get(name) if enclosing

      guard_undefined!(name)
    end

    private
    attr_reader :values, :enclosing

    def guard_undefined!(name)
      raise Lox::RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
    end
  end
end
