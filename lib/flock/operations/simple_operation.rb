module Flock
  class SimpleOperation < SelectOperation
    def initialize(client, query)
      super(client)
      @term = query
    end

    def edges
      Flock::Operation.new do |page|
        query = to_thrift_edges
        query.page = page
        result = @service.select_edges(Array(query)).first
        [result.edges, result.next_cursor, result.prev_cursor]
      end
    end

    def to_thrift
      operation = Edges::SelectOperation.new
      operation.operation_type = Edges::SelectOperationType::SimpleQuery
      operation.term = @term.to_thrift

      Array(operation)
    end

    def to_thrift_edges
      query = Edges::EdgeQuery.new
      query.term = @term.to_thrift
      query
    end
  end
end
