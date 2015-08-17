require 'transflow/step_dsl'
require 'transflow/transaction'

module Transflow
  # @api private
  class FlowDSL
    # @api private
    attr_reader :options

    # @api private
    attr_reader :container

    # @api private
    attr_reader :step_map

    # @api private
    def initialize(options, &block)
      @options = options
      @container = options.fetch(:container)
      @step_map = {}
      instance_exec(&block)
    end

    # @api private
    def steps(*names)
      names.reverse_each { |name| step(name) }
    end

    # @api private
    def step(name, options = {}, &block)
      StepDSL.new(name, options, container, step_map, &block).call
    end

    # @api private
    def call
      Transaction.new(step_map)
    end
  end
end
