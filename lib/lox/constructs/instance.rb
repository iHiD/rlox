module Lox
  module Constructs
    class Instance < Callable
      def initialize(klass)
        @klass = klass
        @fields = {}
      end

      def get(identifier)
        return fields[identifier.lexeme] if fields.key?(identifier.lexeme)

        method = klass.find_method(identifier.lexeme)
        return method.bind(self) if method

        raise RuntimeError.new(identifier, "Undefined property '#{name.lexeme}'.")
      end

      def set(identifier, value)
        fields[identifier.lexeme] = value
      end

      def to_s
        "<Instance of #{klass.name}>"
      end

      private
      attr_reader :klass, :fields
    end
  end
end
