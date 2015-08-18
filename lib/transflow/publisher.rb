require 'wisper'
require 'kleisli'

module Transflow
  class Publisher
    include Wisper::Publisher

    attr_reader :name

    attr_reader :op

    def self.[](name, op, options = {})
      type =
        if options[:monadic]
          Monadic
        else
          self
        end
      type.new(name, op)
    end

    class Monadic < Publisher
      def call(*args)
        op.(*args)
          .or { |result| broadcast_failure(*args, result) and Left(result) }
          .>-> value { broadcast_success(value) and Right(value) }
      end
    end

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
      broadcast_success(result)
      result
    rescue => err
      broadcast_failure(*args, err) and raise(err)
    end
    alias_method :[], :call

    def subscribe(listeners, *args)
      Array(listeners).each { |listener| super(listener, *args) }
    end

    private

    def broadcast_success(result)
      broadcast(:"#{name}_success", result)
    end

    def broadcast_failure(*args, err)
      broadcast(:"#{name}_failure", *args, err)
    end
  end
end
