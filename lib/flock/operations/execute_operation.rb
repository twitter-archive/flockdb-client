module Flock
  class ExecuteOperation
    def initialize(operation_type, query)
      @operation_type, @query = operation_type, query
    end

    def to_thrift
      op = Edges::ExecuteOperation.new
      op.operation_type = @operation_type
      op.term = QueryTerm.new(@query).to_thrift
      op
    end
  end
end
