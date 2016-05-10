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
    attr_reader :step_options

    # @api private
    def initialize(options, &block)
      @options = options
      @container = options.fetch(:container)
      @step_map = {}
      @step_options = {}
      instance_exec(&block)
    end

    # @api public
    def steps(*names)
      names.each { |name| step(name) }
    end

    # @api public
    def step(name, options = {}, &block)
      StepDSL.new(name, step_options.merge(options), container, step_map, &block).call
    end

    # @api public
    def monadic(value)
      step_options.update(monadic: value)
    end

    # @api public
    def publish(value)
      step_options.update(publish: value)
    end

    # @api private
    def call
      Transaction.new(step_map)
    end
  end
end
