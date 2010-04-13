module Flock
  class ExecuteOperations
    def initialize(service, priority)
      @service, @operations, @priority = service, [], priority
    end

    def add(source_id, graph_id, destination_id)
      @operations << ExecuteOperation.new(Edges::ExecuteOperationType::Add, [source_id, graph_id, destination_id])
      self
    end

    def remove(source_id, graph_id, destination_id)
      @operations << ExecuteOperation.new(Edges::ExecuteOperationType::Remove, [source_id, graph_id, destination_id])
      self
    end

    def archive(source_id, graph_id, destination_id)
      @operations << ExecuteOperation.new(Edges::ExecuteOperationType::Archive, [source_id, graph_id, destination_id])
      self
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

    alias_method :unarchive, :add
  end
end
