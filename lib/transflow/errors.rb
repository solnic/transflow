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

    def initialize(input = nil)
      if input.kind_of?(StandardError)
        @original_error = input
        super(@original_error.message)
        set_backtrace(original_error.backtrace)
      else
        super(input)
      end
    end
  end
end
