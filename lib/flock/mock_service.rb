module Flock
  class MockService

    EXEC_OPS = {
      Edges::ExecuteOperationType::Add => :add,
      Edges::ExecuteOperationType::Remove => :remove,
      Edges::ExecuteOperationType::Archive => :archive,
      Edges::ExecuteOperationType::Negate => :negate
    }
    OP_COLOR_MAP = {:add => 0, :remove => 1, :archive => 2, :negate => 3}

    attr_accessor :timeout, :fixtures

    def clear
      @graphs = nil
    end

    def load_yml(file)
      @data_for_fixture ||= Hash.new do |h, k|
        h[k] = YAML::load(ERB.new(File.open(k, 'r').read).result(binding)).sort
      end
      @data_for_fixture[file]
    end

    def load(fixtures = nil)
      fixtures ||= self.fixtures or raise "No flock fixtures specified. either pass fixtures to load, or set Flock::MockService.fixtures."
      clear

      fixtures.each do |fixture|
        file, graph, source, dest = fixture.values_at(:file, :graph, :source, :destination)

        load_yml(file).each do |key, row|
          color_node(row[source], graph, row[dest], OP_COLOR_MAP[:add])
        end
      end
    end

    def inspect
      "Flock::MockService: ( #{@forward_edges.inspect} - #{@backward_edges.inspect} )"
    end

    def execute(operations)
      operations = operations.operations
      operations.each do |operation|
        term = operation.term
        position = operation.position
        graph, source = term.graph_id, term.source_id
        destinations = term.destination_ids && term.destination_ids.unpack('Q*')
        dest_state = OP_COLOR_MAP[EXEC_OPS[operation.operation_type]]

        source, destinations = destinations, source unless term.is_forward
        color_node(source, graph, destinations, dest_state, position)
      end
    end

    def select(select_operations, page)
      data, next_cursor, prev_cursor = paginate(select_query(select_operations), page)

      result = Flock::Results.new
      result.ids = data.pack("Q*")
      result.next_cursor = next_cursor
      result.prev_cursor = prev_cursor
      result
    end

    def select2(queries)
      queries.map do |query|
        select(query.operations, query.page)
      end
    end

    def select_edges(queries)
      queries.map do |query|
        edges, next_cursor, prev_cursor = paginate(simple_query(query.term), query.page)
        result = Edges::EdgeResults.new
        result.edges = if query.term.is_forward
           edges.map(&:dup)
         else
           edges.map(&:dup).map do |edge|
             edge.source_id, edge.destination_id = edge.destination_id, edge.source_id
             edge
           end
         end
        result.next_cursor = next_cursor
        result.prev_cursor = prev_cursor
        result
      end
    end

    def contains(source, graph, dest)
      graphs(graph).contains?(source, dest, Edges::EdgeState::Positive)
    end

    def count(select_operations)
      select_query(select_operations).size
    end

    private

    def select_query(select_operations)
      stack = []
      select_operations.each do |select_operation|
        case select_operation.operation_type
        when Edges::SelectOperationType::SimpleQuery
          term = select_operation.term
          matching_edges = simple_query(term)
          ids = if term.is_forward
            matching_edges.map(&:destination_id)
          else
            matching_edges.map(&:source_id)
          end
          stack.push(ids)
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

    def simple_query(term)
      destination_ids = term.destination_ids && term.destination_ids.unpack("Q*")
      states = term.state_ids || [Edges::EdgeState::Positive]
      graph = graphs(term.graph_id)
      if term.is_forward
        graph.select_edges(term.source_id, destination_ids, states)
      else
        graph.select_edges(destination_ids, term.source_id, states)
      end
    end

    def paginate(data, page)
      return empty_result if page.cursor == Flock::CursorEnd

      start =
        if page.cursor < Flock::CursorStart
          [-page.cursor - page.count, 0].max
        else
          page.cursor == Flock::CursorStart ? 0 : page.cursor
        end
      rv = data.slice(start, page.count)
      next_cursor = (start + page.count >= data.size) ? Flock::CursorEnd : start + page.count
      prev_cursor = (start <= 0) ? Flock::CursorEnd : -start
      [Array(rv), next_cursor, prev_cursor]
   end

    def empty_result
      @empty_result ||=
        begin
          empty_result = Flock::Results.new
          empty_result.ids = ""
          empty_result.next_cursor = Flock::CursorEnd
          empty_result.prev_cursor = Flock::CursorEnd
          empty_result
        end
    end

    def graphs(graph_id)
      (@graphs ||= Hash.new do |h, k|
        h[k] = Graph.new
      end)[graph_id]
    end


    def color_node(source, graph_id, dest, dest_state, position = nil)
      raise ArgumentError unless Edges::EdgeState::VALUE_MAP.keys.include? dest_state
      raise ArgumentError if source.nil? && dest.nil?
      position ||= Time.now.to_i

      if source.nil? || dest.nil?
        existing_edges = graphs(graph_id).select_edges(source, dest)
        existing_edges.each do |existing_edge|
          graphs(graph_id).add_edge(dest_state, existing_edge.source_id, existing_edge.destination_id, Time.now, position)
        end
      else
        Array(source).each do |s|
          Array(dest).each do |d|
            graphs(graph_id).add_edge(dest_state, s, d, Time.now, position)
          end
        end
      end
    end

  end

  class Graph
    def initialize
      @by_pair, @by_source, @by_destination = {}, Hash.new { |h, k| h[k] = [] }, Hash.new { |h, k| h[k] = [] }
    end

    def add_edge(state, source, dest, time, pos)
      if existing_edge = @by_pair[[source, dest]]
        if existing_edge.state_id != Edges::EdgeState::Archived && state == Edges::EdgeState::Positive
          existing_edge.position = pos << 20
        end
        existing_edge.state_id = state
        existing_edge.updated_at = time.to_i
      else
        edge = make_edge(state, source, dest, time, pos)
        @by_pair[[source, dest]] = edge
        @by_source[source] << edge
        @by_destination[dest] << edge
      end
    end

    def select_edges(source_ids, destination_ids, states = [])
      source_ids, destination_ids, states = Array(source_ids), Array(destination_ids), Array(states)
      result = []
      if source_ids.empty?
        destination_ids.each do |destination_id|
          @by_destination[destination_id].each do |edge|
            next unless states.empty? || states.include?(edge.state_id)

            result << edge
          end
        end
      elsif destination_ids.empty?
        source_ids.each do |source_id|
          @by_source[source_id].each do |edge|
            next unless states.empty? || states.include?(edge.state_id)

            result << edge
          end
        end
      else
        source_ids.each do |source_id|
          destination_ids.each do |destination_id|
            next unless existing_edge = @by_pair[[source_id, destination_id]]
            next unless states.empty? || states.include?(existing_edge.state_id)

            result << existing_edge
          end
        end
      end
      result
    end

    def contains?(source, dest, state)
      select_edges(source, dest, state).any?
    end

    private
    def make_edge(state, source, dest, time, pos)
      Edges::Edge.new.tap do |edge|
        edge.source_id = source
        edge.destination_id = dest
        edge.updated_at = time.to_i
        edge.position = pos << 20
        edge.count = 1
        edge.state_id = state
      end
    end
  end
end
