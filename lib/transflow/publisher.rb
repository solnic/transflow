require 'wisper'

module Transflow
  class Publisher
    include Wisper::Publisher

    attr_reader :name

    attr_reader :op

    class Curried < Publisher
      attr_reader :publisher

      attr_reader :arity

      attr_reader :curry_args

      def initialize(publisher, curry_args = [])
        @publisher = publisher
        @arity = publisher.arity
        @curry_args = curry_args
      end

      def call(*args)
        all_args = curry_args + args

        if all_args.size == arity
          publisher.call(*all_args)
        else
          self.class.new(publisher, all_args)
        end
      end

      def subscribe(*args)
        publisher.subscribe(*args)
      end
    end

    def initialize(name, op)
      @name = name
      @op = op
    end

    def curry
      raise "can't curry publisher where operation arity is < 0" if arity < 0
      Curried.new(self)
    end

    def arity
      op.is_a?(Proc) ? op.arity : op.method(:call).arity
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
