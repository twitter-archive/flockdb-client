module Flock
  class ExecuteOperations
    def initialize(service, priority, execute_at = nil)
      @service, @operations, @priority, @execute_at = service, [], priority, execute_at 
    end

    Flock::Edges::ExecuteOperationType::VALUE_MAP.each do |op_id, op|
      op = op.downcase
      class_eval "def #{op}(s, g, d); @operations << ExecuteOperation.new(#{op_id}, [s, g, d]); self end", __FILE__, __LINE__
    end

    def apply
      @service.execute(to_thrift)
    end

    def to_thrift
      operations = Edges::ExecuteOperations.new
      operations.operations = @operations.map(&:to_thrift)
      operations.priority = @priority
      operations.execute_at = @execute_at.to_i if @execute_at
      operations
    end
  end
end
