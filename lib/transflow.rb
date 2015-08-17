require 'transflow/version'
require 'transflow/flow_dsl'

# Define a business transaction flow.
#
# A business transaction flow is a simple composition of callable objects that
# receive an input and produce an output. Steps are registered in the same order
# they are defined within the DSL and that's also the order of execution.
#
# Initial input is sent to the first step, its output is sent to the second step
# and so on.
#
# Every step can become a publisher, which means you can broadcast results from
# any step and subscribe event listeners to individual steps. This gives you
# a flexible way of responding to successful or failed execution of individual
# steps.
#
# @example
#   container = { do_one: some_obj, do_two: some_obj }
#
#   my_business_flow = Transflow(container: container) do
#     step(:one, with: :do_one) { step(:two, with: :do_two }
#   end
#
#   my_business_flow[some_input]
#
#   # with events
#
#   my_business_flow = Transflow(container: container) do
#     step(:one, with: :do_one) { step(:two, with: :do_two, publish: true) }
#   end
#
#   class Listener
#     def self.do_two_success(*args)
#       puts ":do_two totally worked and produced: #{args.inspect}!"
#     end
#   end
#
#   my_business_flow.subscribe(do_two: Listener)
#
#   my_business_flow[some_input]
#
# @options [Hash] options The option hash
#
# @api public
def Transflow(options = {}, &block)
  Transflow::FlowDSL.new(options, &block).call
end
