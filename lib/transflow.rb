require 'transflow/version'
require 'transflow/flow_dsl'

# Define a transaction flow
#
# @example
#
#   container = { do_one: some_obj, do_two: some_obj }
#
#   my_business_flow = Transflow(container: container) do
#     step(:one, with: :do_one) { step(:two, with: :do_two }
#   end
#
#   my_business_flow[some_input]
#
# @options [Hash] options The option hash
#
# @api public
def Transflow(options = {}, &block)
  Transflow::FlowDSL.new(options, &block).call
end
