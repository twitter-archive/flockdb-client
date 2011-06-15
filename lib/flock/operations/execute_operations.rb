module Flock
  class ExecuteOperations
    def initialize(service, priority, execute_at = nil)
      @service, @operations, @priority, @execute_at = service, [], priority, execute_at
    end

    Flock::Edges::ExecuteOperationType::VALUE_MAP.each do |op_id, op|
      op = op.downcase
      class_eval <<-EOT, __FILE__, __LINE__ + 1
        def #{op}(s, g, d, p = nil)
          @operations << ExecuteOperation.new(#{op_id}, Flock::QueryTerm.new([s, g, d]), p)
          self
        end
      EOT
    end

    ##Flock::Edges::ExecuteOperationType::VALUE_MAP.each do |op_id, op|
    ##  op = op.downcase
    ##  class_eval "def #{op}(s, g, d, p = nil); @operations << ExecuteOperation.new(#{op_id}, [s, g, d], p); self end", __FILE__, __LINE__
    ##end

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
