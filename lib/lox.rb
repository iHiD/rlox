require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

# Require all the types defined in here
# as this doesn't conform to zietwerk
require 'lox/expr'

# This also has requires that are needed
require 'lox/token' 

module Lox
  def self.exec!(args)
    Program.exec!(args)
  end
end
