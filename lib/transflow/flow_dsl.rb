require 'transproc'

require 'transflow/step_dsl'
require 'transflow/transaction'

module Transflow
  class FlowDSL
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
      steps.values.reverse.map { |op| self.class[op] }
    end
  end
end
