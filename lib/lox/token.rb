module Lox
  class Token
    def initialize(type, lexeme, literal, line)
      @type = type
      @lexeme = lexeme
      @literal = literal
      @line = line
    end

    def to_s
      "#{type} | #{lexeme} | #{literal} | #{line}"
    end

    def inspect
      type
    end

    attr_reader :type, :lexeme, :literal, :line
  end
end

require_relative 'token/types'
require_relative 'token/keywords'
