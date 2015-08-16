require 'wisper'

module Transflow
  class Publisher
    include Wisper::Publisher

    attr_reader :name

    attr_reader :op

    def initialize(name, op)
      @name = name
      @op = op
    end

    def call(*args)
      result = op.call(*args)
      broadcast(:"#{name}_success", result)
      result
    end
    alias_method :[], :call
  end
end
