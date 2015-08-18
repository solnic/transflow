require 'dry-pipeline'

module Transflow
  class TransactionFailedError < StandardError
    attr_reader :transaction

    attr_reader :original_error

    def initialize(transaction, original_error)
      @transaction = transaction
      @original_error = original_error

      super("#{transaction} failed [#{original_error.class}: #{original_error.message}]")

      set_backtrace(original_error.backtrace)
    end
  end

  class StepError < StandardError
    attr_reader :original_error

    def initialize(input)
      if input.kind_of?(StandardError)
        @original_error = input
        super(@original_error.message)
        set_backtrace(original_error.backtrace)
      else
        super(input)
      end
    end
  end

  # Transaction encapsulates calling individual steps registered within a transflow
  # constructor.
  #
  # It's responsible for calling steps in the right order and optionally currying
  # arguments for specific steps.
  #
  # Furthermore you can subscribe event listeners to individual steps within a
  # transaction.
  #
  # @api public
  class Transaction
    # Internal function factory using Transproc extension
    #
    # @api private
    class Step
      include Dry::Pipeline

      # @api private
      def self.[](op)
        if op.respond_to?(:>>)
          op
        else
          Step.new(op)
        end
      end
    end

    # @attr_reader [Hash<Symbol => Proc,#call>] steps The step map
    #
    # @api private
    attr_reader :steps

    # @attr_reader [Array<Symbol>] step_names The names of registered steps
    #
    # @api private
    attr_reader :step_names

    # @api private
    def initialize(steps)
      @steps = steps
      @step_names = steps.keys.reverse
    end

    # Subscribe event listeners to specific steps
    #
    # @example
    #   transaction = Transflow(container: my_container) {
    #     step(:one) { step(:two, publish: true }
    #   }
    #
    #   class MyListener
    #     def self.two_success(*args)
    #       puts 'yes!'
    #     end
    #
    #     def self.two_failure(*args)
    #       puts 'oh noez!'
    #     end
    #   end
    #
    #   transaction.subscribe(two: my_listener)
    #
    #   transaction.call(some_input)
    #
    # @param [Hash<Symbol => Object>] listeners The step=>listener map
    #
    # @return [self]
    #
    # @api public
    def subscribe(listeners)
      listeners.each { |step, listener| steps[step].subscribe(listener) }
      self
    end

    # Call the transaction
    #
    # Once transaction is called it will call the first step and its result
    # will be passed to the second step and so on.
    #
    # @example
    #   my_container = {
    #     add_one: -> i { i + 1 },
    #     add_two: -> j { j + 2 }
    #   }
    #
    #   transaction = Transflow(container: my_container) {
    #     step(:one, with: :add_one) { step(:two, with: :add_two) }
    #   }
    #
    #   transaction.call(1) # 4
    #
    # @param [Object] input The input for the first step
    #
    # @param [Hash] options The curry-args map, optional
    #
    # @return [Object]
    #
    # @raises TransactionFailedError
    #
    # @api public
    def call(input, options = {})
      handler = handler_steps(options).map(&method(:step)).reduce(:>>)
      handler.call(input)
    rescue StepError => err
      raise TransactionFailedError.new(self, err)
    end
    alias_method :[], :call

    # Coerce a transaction into string representation
    #
    # @return [String]
    #
    # @api public
    def to_s
      "Transaction(#{step_names.join(' => ')})"
    end

    private

    # @api private
    def handler_steps(options)
      if options.any?
        assert_valid_options(options)

        steps.map { |(name, op)|
          args = options[name]

          if args
            op.curry.call(args)
          else
            op
          end
        }
      else
        steps.values
      end.reverse
    end

    # @api private
    def assert_valid_options(options)
      options.each_key do |name|
        unless step_names.include?(name)
          raise ArgumentError, "+#{name}+ is not a valid step name"
        end
      end
    end

    # Wrap a proc into composable transproc function
    #
    # @param [#call]
    #
    # @api private
    def step(obj)
      Step[obj]
    end
  end
end
