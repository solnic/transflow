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
    rescue => err
      broadcast(:"#{name}_failure", *args, err)
      raise err
    end
    alias_method :[], :call
  end
end
