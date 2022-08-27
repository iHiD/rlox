module Lox
  module Constructs
    class Class < Callable
      attr_reader :name, :methods

      def initialize(name, methods)
        @name = name
        @methods = methods
      end

      def call(interpreter, args)
        Constructs::Instance.new(self).tap do |instance|
          initializer = find_method("init")
          initializer.bind(instance).call(interpreter, args) if initializer
        end
      end

      def find_method(name)
        methods[name]
      end

      def arity 
        find_method("init")&.arity.to_i
      end

      def to_s
        name
      end
    end
  end
end
