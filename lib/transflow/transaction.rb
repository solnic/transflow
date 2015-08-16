require 'transproc'

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

  class Transaction
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

    attr_reader :steps

    def initialize(steps)
      @steps = steps
    end

    def subscribe(listeners)
      listeners.each { |step, listener| steps[step].subscribe(listener) }
    end

    def call(input, options = {})
      handler =
        if options.any?
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
        end.map(&method(:fn)).reverse.reduce(:>>)

      handler.call(input)
    rescue Transproc::MalformedInputError => err
      raise TransactionFailedError.new(self, err.original_error)
    end
    alias_method :[], :call

    def to_s
      "Transaction(#{steps.keys.join(' => ')})"
    end

    def fn(obj)
      self.class[obj]
    end
  end
end
