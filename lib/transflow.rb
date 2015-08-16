require 'transflow/version'
require 'transflow/flow_dsl'

def Transflow(options = {}, &block)
  Transflow::FlowDSL.new(options, &block).call
end
