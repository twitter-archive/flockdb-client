module Flock
  class ExecuteOperations
    def initialize(service, priority)
      @service, @operations, @priority = service, [], priority
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
      operations
    end
  end
end
