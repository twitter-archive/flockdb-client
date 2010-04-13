module Flock
  module MockService
    extend self

    attr_accessor :timeout, :fixtures

    def clear
      @sources = @destinations = nil
    end

    def load(fixtures = nil)
      fixtures ||= self.fixtures or raise "No flock fixtures specified. either pass fixtures to load, or set Flock::MockService.fixtures."

      clear

      fixtures.each do |fixture|
        file, graph_id, source, destination = fixture.values_at(:file, :graph, :source, :destination)

        fixtures_data = YAML::load(ERB.new(File.open(file, 'r').read).result(binding)).sort
        fixtures_data.each do |key, value|
          sources[[value[destination], graph_id]] << value[source]
          destinations[[value[source], graph_id]] << value[destination]
        end
      end
    end

    def inspect
      "Flock::MockService: " + @sources.inspect + " - " + @destinations.inspect
    end

    def execute(operations)
      operations = operations.operations
      operations.each do |operation|
        term = operation.term
        backward_data_source, forward_data_source = term.is_forward ? [sources, destinations] : [destinations, sources]
        backward_archived_data_source, forward_archived_data_source = term.is_forward ? [archived_sources, archived_destinations] : [archived_destinations, archived_sources]
        source_id, graph_id = term.source_id, term.graph_id
        destination_ids = term.destination_ids && term.destination_ids.unpack("Q*")
        case operation.operation_type
        when Edges::ExecuteOperationType::Add
          if destination_ids.nil?
            backward_archived_data_source.delete([source_id, graph_id]).to_a.each do |n|
              (forward_data_source[[n, graph_id]] << source_id).uniq!
              (backward_data_source[[source_id, graph_id]] << n).uniq!
              forward_archived_data_source[[n, graph_id]].delete(source_id)
            end
          else
            destination_ids.each do |destination_id|
              backward_data_source[[destination_id, graph_id]] << source_id
              forward_data_source[[source_id, graph_id]] << destination_id
            end
          end
        when Edges::ExecuteOperationType::Remove
          destination_ids.each do |destination_id|
            backward_data_source[[destination_id, graph_id]].delete(source_id)
            forward_data_source[[source_id, graph_id]].delete(destination_id)
          end
        when Edges::ExecuteOperationType::Archive
          if destination_ids.nil?
            backward_data_source.delete([source_id, graph_id]).to_a.each do |n|
              forward_archived_data_source[[n, graph_id]] << source_id
              backward_archived_data_source[[source_id, graph_id]] << n
              forward_data_source[[n, graph_id]].delete(source_id)
            end
          else
            raise "not yet implemented"
          end
        end
      end
    end

    def select(select_operations, page)
      iterate(select_query(select_operations), page)
    end

    def count(select_operations)
      select_query(select_operations).size
    end

    # FIXME
    def counts_of_sources_for(destination_ids, graph_id)
      destination_ids.unpack("Q*").map do |destination_id|
        (sources[[destination_id, graph_id]] || []).size
      end.pack("I*")
    end

    private
    def select_query(select_operations)
      stack = []
      select_operations.each do |select_operation|
        case select_operation.operation_type
        when Edges::SelectOperationType::SimpleQuery
          query_term = select_operation.term
          data_source = query_term.is_forward ? destinations : sources
          data = data_source[[query_term.source_id, query_term.graph_id]]
          if query_term.destination_ids
            data &= query_term.destination_ids.unpack("Q*")
          end
          stack.push(data)
        when Edges::SelectOperationType::Intersection
          stack.push(stack.pop & stack.pop)
        when Edges::SelectOperationType::Union
          stack.push(stack.pop | stack.pop)
        when Edges::SelectOperationType::Difference
          operand2 = stack.pop
          operand1 = stack.pop
          stack.push(operand1 - operand2)
        end
      end
      stack.pop
    end

    private

    def iterate(data, page)
      return empty_result if page.cursor == Flock::CursorEnd

      start = if page.cursor < Flock::CursorStart
                [-page.cursor - page.count, 0].max
              else
                page.cursor == Flock::CursorStart ? 0 : page.cursor
              end
      rv = data.slice(start, page.count)
      next_cursor = (start + page.count >= data.size) ? Flock::CursorEnd : start + page.count
      prev_cursor = (start <= 0) ? Flock::CursorEnd : -start

      result = Flock::Results.new
      result.ids = Array(rv).pack("Q*")
      result.next_cursor = next_cursor
      result.prev_cursor = prev_cursor
      result
    end

    def empty_result
      @empty_result ||= begin
                          empty_result = Flock::Results.new
                          empty_result.ids = ""
                          empty_result.next_cursor = Flock::CursorEnd
                          empty_result.prev_cursor = Flock::CursorEnd
                          empty_result
                        end
    end

    def sources
      @sources ||= Hash.new do |h, k|
        h[k] = []
      end
    end

    def destinations
      @destinations ||= Hash.new do |h, k|
        h[k] = []
      end
    end

    def archived_sources
      @archived_sources ||= Hash.new do |h, k|
        h[k] = []
      end
    end

    def archived_destinations
      @archived_destinations ||= Hash.new do |h, k|
        h[k] = []
      end
    end

    # deprecated
    public
    def offset_sources_for(destination_id, graph_id, offset, count)
      (sources[[destination_id, graph_id]].slice(offset, count) || []).pack("Q*")
    end

    def offset_destinations_for(source_id, graph_id, offset, count)
      (destinations[[source_id, graph_id]].slice(offset, count) || []).pack("Q*")
    end
  end
end
