module Lox
  module Constructs
    class Function < Callable
      def initialize(declaration, closure, initializer: false)
        @declaration = declaration
        @closure = closure.dup
        @initializer = initializer
      end

      def bind(instance)
        env = Environment.new(enclosing: closure)
        env.define('this', instance)
        self.class.new(declaration, env)
      end

      def arity
        declaration.params.size
      end

      def to_s
        "<fn #{declaration.identifier.lexeme}>"
      end

      def call(interpreter, args)
        env = Environment.new(enclosing: closure)
        args.each.with_index do |arg, idx|
          env.define(declaration.params[idx].lexeme, arg)
        end

        begin
          ret = interpreter.execute_block(declaration.body, env)
        rescue ReturnControlFlow => e
          initializer? ? closure.this : e.value
        end
      end

      private
      attr_reader :declaration, :closure

      def initializer?
        !!@initializer
      end
    end
  end
end
