module Flock
  class SelectOperation
    [:each, :paginate, :to_ary, :size, :first].each do |method|
      class_eval("def #{method}(*args, &block); operation.#{method}(*args, &block) end", __FILE__, __LINE__)
    end

    include Enumerable
    include Mixins::Sizeable

    def initialize(client)
      @client = client
      @service = client.service
    end

    def intersect(*args)
      other = _operation_from_args(args)
      ComplexOperation.new(@client, Edges::SelectOperationType::Intersection, self, other)
    end

    def union(*args)
      other = _operation_from_args(args)
      ComplexOperation.new(@client, Edges::SelectOperationType::Union, self, other)
    end

    def difference(*args)
      other = _operation_from_args(args)
      ComplexOperation.new(@client, Edges::SelectOperationType::Difference, self, other)
    end

    def get_results(page)
      @service.select(to_thrift, page)
    end

    def size
      @service.count(to_thrift)
    end

    def operation
      Flock::Operation.new do |page|
        results = get_results(page)
        [results.ids.unpack("Q*"), results.next_cursor, results.prev_cursor]
      end
    end

    private

    def _operation_from_args(args)
      args.first.is_a?(SelectOperation) ? args.first : @client.select(*args)
    end
  end
end
