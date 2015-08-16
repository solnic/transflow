module Transflow
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
    end
    alias_method :[], :call
  end
end
