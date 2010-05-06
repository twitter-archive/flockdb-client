module Flock
  class QueryTerm
    def initialize(query, state = [Flock::Edges::EdgeState::Positive])
      @query = query
      @state = state
    end

    def to_thrift
      raise ArgumentError unless @query.size == 3

      term = Edges::QueryTerm.new
      case @query.first
      when Numeric
        term.source_id = @query.first
        term.destination_ids = Array(@query.last).pack("Q*") if @query.last
        term.is_forward = true
      else
        term.source_id = @query.last
        term.destination_ids = Array(@query.first).pack("Q*") if @query.first
        term.is_forward = false
      end
      term.graph_id = @query[1]
      term.state_ids = @state
      term
    end
  end
end
