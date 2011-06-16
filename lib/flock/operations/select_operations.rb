module Flock
  class SelectOperations
    EMPTY = Flock::Operation.new do |page|
      [[], Flock::CursorEnd, Flock::CursorEnd]
    end

    [:each, :to_ary, :size, :first].each do |method|
      class_eval("def #{method}(*args, &block); operation.#{method}(*args, &block) end", __FILE__, __LINE__)
    end

    include Enumerable

    def initialize(client)
      @client = client
      @service = client.service
      @selecticons = []
    end

    def select(*query)
      selecticon = Selecticon.new(Flock::QueryTerm.new(query, @client.graphs))
      @selecticons << selecticon
      selecticon
    end

    def to_thrift_edges
      @selecticons.map do |selecticon|
        selecticon.to_thrift_edges
      end
    end

    def to_thrift_ids
      @selecticons.map do |selecticon|
        selecticon.to_thrift_ids
      end
    end

    def operation
      if @selecticons.any?
        @service.select2(to_thrift_ids).map do |results|
          # Note: pagination will not work for now.
          Flock::Operation.new do |page|
            [results.ids.unpack("Q*"), Flock::CursorEnd, Flock::CursorEnd]
          end
        end
      else
        EMPTY
      end
    end

    def edges
      if @selecticons.any?
        @service.select_edges(to_thrift_edges).map do |results|
          # Note: pagination will not work for now.
          Flock::Operation.new do |page|
            [results.edges, Flock::CursorEnd, Flock::CursorEnd]
          end
        end
      else
        EMPTY
      end
    end

    class Selecticon
      def initialize(term)
        @term = term
        @count, @cursor = 20, Flock::CursorStart
      end

      def paginate(count, cursor = Flock::CursorStart)
        @count, @cursor = count, cursor
      end

      def to_thrift_ids
        query = Edges::SelectQuery.new
        operation = Edges::SelectOperation.new
        operation.operation_type = Edges::SelectOperationType::SimpleQuery
        operation.term = @term.to_thrift
        query.operations = [operation]
        page = Flock::Page.new
        page.cursor = @cursor
        page.count = @count
        query.page = page
        query
      end

      def to_thrift_edges
        query = Edges::EdgeQuery.new
        query.term = @term.to_thrift
        page = Flock::Page.new
        page.cursor = @cursor
        page.count = @count
        query.page = page
        query
      end
    end
  end
end
