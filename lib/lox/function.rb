module Lox
  class Function < Callable
    def initialize(declaration)
      @declaration = declaration
    end

    def arity
      declaration.params.size
    end

    def to_s
      "<fn #{declaration.name.lexeme}>"
    end

    def call(interpreter, args)
      env = Environment.new(global: true)
      args.each.with_index do |arg, idx|
        env.define(declaration.params[idx].lexeme, arg)
      end

      interpreter.execute_block(declaration.body, env)
    end

    private
    attr_reader :declaration
  end
end

