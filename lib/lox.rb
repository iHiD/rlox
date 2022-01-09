require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

module Lox
  def self.exec!(args)
    Program.exec!(args)
  end
end
