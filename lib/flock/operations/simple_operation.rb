module Flock
  class SimpleOperation < SelectOperation
    def initialize(client, query)
      super(client)
      @query = query
    end

    def to_thrift
      operation = Edges::SelectOperation.new
      operation.operation_type = Edges::SelectOperationType::SimpleQuery
      operation.term = QueryTerm.new(@query, @state).to_thrift

      Array(operation)
    end

    def state(args)
      @state = args
      return self
    end
  end
end
