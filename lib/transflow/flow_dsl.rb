require 'transflow/step_dsl'
require 'transflow/transaction'

module Transflow
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
      Transaction.new(steps)
    end
  end
end
