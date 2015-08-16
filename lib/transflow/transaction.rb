module Transflow
  class TransactionFailedError < StandardError
    attr_reader :transaction

    attr_reader :original_error

    def initialize(transaction, original_error)
      @transaction = transaction
      @original_error = original_error

      super("#{transaction} failed")

      set_backtrace(original_error.backtrace)
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

    def call(input, options = {})
      if options.any?
        curried_handler = steps.map { |(name, op)|
          args = options[name]

          curried =
            if args
              op.curry.call(*args)
            else
              op
            end

          FlowDSL[curried]
        }.reverse.reduce(:>>)

        curried_handler.call(input)
      else
        handler.call(input)
      end
    rescue Transproc::MalformedInputError => err
      raise TransactionFailedError.new(self, err)
    end
    alias_method :[], :call

    def to_s
      "Transaction(#{steps.keys.join(' => ')})"
    end
  end
end
