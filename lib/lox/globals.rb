module Lox
  module Globals
    class Clock < Callable
      def arity; 0; end

      def call(...)
        Time.now.to_i
      end

      def to_s
        "<native fn>"
      end
    end
  end
end
