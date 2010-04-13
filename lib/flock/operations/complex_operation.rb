module Flock
  class ComplexOperation < SelectOperation
    def initialize(client, operation_type, operand1, operand2)
      super(client)
      @operation_type, @operand1, @operand2 = operation_type, operand1, operand2
    end

    def to_thrift
      operation = Edges::SelectOperation.new
      operation.operation_type = @operation_type
      operation.term = nil
      @operand1.to_thrift + @operand2.to_thrift + Array(operation)
    end
  end
end
