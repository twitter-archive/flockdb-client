module Flock
  class QueryTerm
    attr_reader :states, :query
    def initialize(query)
      if query.size <= 3
        @states = [:positive]
      else
        @states = query[3..-1]
      end
      @query = query[0..2]
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
      term.state_ids = @states.collect { |state| value_of(state) }
      term
    end

    def value_of(sym)
      Flock::Edges::EdgeState::VALUE_MAP.each do |k, v|
        if sym == v.downcase.to_sym
          return k
        end
      end
    end
  end
end
