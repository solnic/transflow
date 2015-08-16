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

    def call(*args)
      handler.call(*args)
    rescue Transproc::MalformedInputError => err
      raise TransactionFailedError.new(self, err)
    end
    alias_method :[], :call

    def to_s
      "Transaction(#{steps.keys.join(' => ')})"
    end
  end
end
