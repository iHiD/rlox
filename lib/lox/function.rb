module Lox
  class Function < Callable
    def initialize(declaration, closure)
      @declaration = declaration
      @closure = closure.dup
    end

    def arity
      declaration.params.size
    end

    def to_s
      "<fn #{declaration.name.lexeme}>"
    end

    def call(interpreter, args)
      env = Environment.new(enclosing: closure)
      args.each.with_index do |arg, idx|
        env.define(declaration.params[idx].lexeme, arg)
      end

      interpreter.execute_block(declaration.body, env)
    end

    private
    attr_reader :declaration, :closure
  end
end

