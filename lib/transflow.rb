require 'transproc'
require 'transflow/version'

module Transflow
  class Transaction
    attr_reader :handler

    attr_reader :steps

    def initialize(steps, handler)
      @steps = steps
      @handler = handler
    end

    def call(*args)
      handler.call(*args)
    end
    alias_method :[], :call
  end

  class StepDSL
    attr_reader :name

    attr_reader :handler

    attr_reader :container

    attr_reader :steps

    def initialize(name, options, container, steps, &block)
      @name = name
      @handler = options.fetch(:with)
      @container = container
      @steps = steps
      instance_exec(&block) if block
    end

    def step(*args, &block)
      self.class.new(*args, container, steps, &block).call
    end

    def call
      steps[name] = container[handler]
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
      Transaction.new(steps, steps.values.reverse.reduce(:>>))
    end
  end
end

def Transflow(options = {}, &block)
  Transflow::FlowDSL.new(options, &block).call
end
