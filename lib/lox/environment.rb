module Lox
  class Environment
    attr_reader :enclosing

    def initialize(enclosing: nil, global: true)
      @values = {}
      @enclosing = enclosing.dup

      define('clock', Globals::Clock.new) if global
    end

    def dup
      super
      # This fixes the scoping issue too
      # super.tap {|e| e.instance_variable_set("@values",  values.dup) }
    end

    def get_value(name)
      values[name]
    end

    def set_value(name, value)
      values[name] = value
    end


    def define(name, value)
      values[name] = value
    end

    def assign(identifier, value)
      if values.key?(identifier.lexeme)
        values[identifier.lexeme] = value
        return
      end

      return enclosing.assign(identifier, value) if enclosing

      guard_undefined!(identifier)
    end

    def assign_at(distance, identifier, value)
      env = self
      distance.times { env = env.enclosing }
      env.set_value(identifier.lexeme, value)
    end

    def get(identifier)
      return values[identifier.lexeme] if values.key?(identifier.lexeme)
      return enclosing.get(identifier) if enclosing

      guard_undefined!(identifier)
    end

    def get_at(distance, name)
      env = self
      distance.times { env = env.enclosing }
      env.get_value(name)
    end

    private
    attr_reader :values

    def guard_undefined!(identifier)
      raise Lox::RuntimeError.new(identifier, "Undefined variable '#{identifier.lexeme}'.")
    end
  end
end
