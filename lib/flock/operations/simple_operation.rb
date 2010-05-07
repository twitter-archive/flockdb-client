module Flock
  class SimpleOperation < SelectOperation
    def initialize(client, query)
      super(client)
      @query = query
    end

    def to_thrift
      operation = Edges::SelectOperation.new
      operation.operation_type = Edges::SelectOperationType::SimpleQuery
      operation.term = QueryTerm.new(@query).to_thrift

      Array(operation)
    end
  end
end
