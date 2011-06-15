# external dependencies
require 'thrift'
require 'thrift_client'

require 'flock/mixins/sizeable'

# thrift sources. load order is important.
$LOAD_PATH << File.join(File.dirname(__FILE__), 'flock', 'gen-rb')

require 'flockdb_types'
require 'flockdb_constants'
require 'flock_d_b'

module Flock
  autoload :MockService,       'flock/mock_service'
  autoload :Operation,         'flock/operation'
  autoload :QueryTerm,         'flock/operations/query_term'
  autoload :SelectOperation,   'flock/operations/select_operation'
  autoload :ComplexOperation,  'flock/operations/complex_operation'
  autoload :SimpleOperation,   'flock/operations/simple_operation'
  autoload :ExecuteOperation,  'flock/operations/execute_operation'
  autoload :ExecuteOperations, 'flock/operations/execute_operations'
  autoload :SelectOperations,  'flock/operations/select_operations'
  autoload :Service,           'flock/service'
  autoload :Client,            'flock/client'

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
      super("Unable to look up id for state #{state.inspect}. Valid states are #{ Flock::QueryTerm::STATES.keys.map{|s| s.inspect }.join(', ') }")
    end
  end

  class << self
    attr_accessor :default_service_class, :graphs

    def new(*args)
      Flock::Client.new(*args)
    end
  end
end
