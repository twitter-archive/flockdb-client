module Flock
  class QueryTerm
    # symbol => state_id map
    STATES = Flock::Edges::EdgeState::VALUE_MAP.inject({}) do |states, (id, name)|
      states.update name.downcase.to_sym => id
    end.freeze

    attr_accessor :source, :graph, :destination, :states

    def initialize(query, graphs = nil)
      raise ArgumentError if query.size < 3
      @graphs = graphs

      @source, @graph, @destination, @states = *query_args(query)
    end

    def forward?
      @source.is_a? Numeric
    end

    def unapply
      [@source, @graph, @destination, @states]
    end

    def to_thrift
      term = Edges::QueryTerm.new
      term.graph_id = @graph
      term.state_ids = @states unless @states.nil? or @states.empty?
      term.is_forward = forward?

      source, destination =
        if term.is_forward
          [@source, @destination]
        else
          [@destination, @source]
        end

      term.source_id = source
      term.destination_ids = Array(destination).pack("Q*") if destination

      term
    end

    def ==(other)
      self.source == other.source &&
        self.graph == other.graph &&
        self.destination == other.destination &&
        self.states == other.states
    end

    private

    def lookup_graph(key)
      if @graphs.nil? or key.is_a? Integer
        key
      else
        @graphs[key] or raise UnknownGraphError.new(key)
      end
    end

    def lookup_states(states)
      states = states.flatten.compact.map do |s|
        if s.is_a? Integer
          s
        else
          STATES[s] or raise UnknownStateError.new(s)
        end
      end
    end

    def query_args(args)
      source, graph, destination, *states = *((args.length == 1) ? args.first : args)
      [node_arg(source), lookup_graph(graph), node_arg(destination), lookup_states(states)]
    end

    def node_arg(node)
      return node.map {|n| n.to_i if n } if node.respond_to? :map
      node.to_i if node
    end
  end
end
