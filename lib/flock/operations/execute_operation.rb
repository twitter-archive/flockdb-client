module Flock
  class ExecuteOperation
    def initialize(operation_type, query, position = nil)
      @operation_type, @query, @position = operation_type, query, position
    end

    def to_thrift
      op = Edges::ExecuteOperation.new
      op.operation_type = @operation_type
      op.term = @query.to_thrift
      op.position = @position if @position
      op
    end
  end
end
