module Lox
  class Token
    def initialize(type, lexeme, literal, line)
      @type = type
      @lexeme = lexeme
      @literal = literal
      @line = line
    end

    def to_s
      "#{type} #{lexeme} #{literal}"
    end

    private
    attr_reader :type, :lexeme, :literal, :line
  end
end

require_relative 'token_types'
