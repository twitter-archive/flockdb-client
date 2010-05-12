module Flock
  class QueryTerm
    attr_accessor :source, :graph, :destination, :states

    def initialize(query)
      case query.size
      when 3, 4
        @source, @graph, @destination, @states = *query
      else
        raise ArgumentError
      end
    end

    def forward?
      @source.is_a? Numeric
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
  end
end
