# external dependencies
require 'thrift'
require 'thrift_client'

require 'flock/mixins/sizeable'

# thrift sources. load order is important.
module Flock
  module Edges
    module FlockDB
    end
  end
end
require 'flock/thrift'

require 'flock/operation'
require 'flock/operations/query_term'
require 'flock/operations/select_operation'
require 'flock/operations/complex_operation'
require 'flock/operations/simple_operation'
require 'flock/operations/execute_operation'
require 'flock/operations/execute_operations'
require 'flock/service'
require 'flock/client'

module Flock
  autoload :MockService, 'flock/mock_service'

  FlockException = Edges::FlockException
  Priority = Edges::Priority
  CursorStart = -1
  CursorEnd = 0
  Page = Edges::Page
  Results = Edges::Results

  class UnknownGraphError < FlockException
    def initialize(graph)
      super("Unable to look up id for graph #{graph.inspect}. Register graphs with Flock.graphs = <graph list>.")
    end
  end

  class UnknownStateError < FlockException
    def initialize(state)
      super("Unable to look up id for state #{state.inspect}. Valid states are #{ Flock::Client::STATES.keys.sort.map{|s| s.inspect }.join(', ') }")
    end
  end

  class << self
    attr_accessor :default_service_class, :graphs

    def new(*args)
      Flock::Client.new(*args)
    end
  end
end
