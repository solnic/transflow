require 'transproc'
require 'wisper'

require 'transflow/version'

module Transflow
  module Registry
    extend Transproc::Registry
  end

  def self.[](op)
    if op.respond_to?(:>>)
      op
    else
      Registry[op]
    end
  end

  class Transaction
    attr_reader :handler

    attr_reader :steps

    def initialize(steps, handler)
      @steps = steps
      @handler = handler
    end

    def subscribe(listeners)
      listeners.each { |step, listener| steps[step].subscribe(listener) }
    end

    def call(*args)
      handler.call(*args)
    end
    alias_method :[], :call
  end

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

  class StepDSL
    attr_reader :name

    attr_reader :handler

    attr_reader :container

    attr_reader :steps

    attr_reader :publish

    def initialize(name, options, container, steps, &block)
      @name = name
      @handler = options.fetch(:with)
      @publish = options.fetch(:publish, false)
      @container = container
      @steps = steps
      instance_exec(&block) if block
    end

    def step(*args, &block)
      self.class.new(*args, container, steps, &block).call
    end

    def call
      operation = container[handler]

      step =
        if publish
          Publisher.new(name, operation)
        else
          operation
        end

      steps[name] = step
    end
  end

  class FlowDSL
    attr_reader :options

    attr_reader :container

    attr_reader :steps

    def initialize(options, &block)
      @options = options
      @container = options.fetch(:container)
      @steps = {}
      instance_exec(&block)
    end

    def step(*args, &block)
      StepDSL.new(*args, container, steps, &block).call
    end

    def call
      Transaction.new(steps, operations.reduce(:>>))
    end

    def operations
      steps.values.reverse.map { |op| Transflow[op] }
    end
  end
end

def Transflow(options = {}, &block)
  Transflow::FlowDSL.new(options, &block).call
end
