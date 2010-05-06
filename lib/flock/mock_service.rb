module Flock
  module MockService
    extend self

    EXEC_OPS = {
      Edges::ExecuteOperationType::Add => :add,
      Edges::ExecuteOperationType::Remove => :remove,
      Edges::ExecuteOperationType::Archive => :archive,
      Edges::ExecuteOperationType::Negate => :negate
    }

    attr_accessor :timeout, :fixtures

    def clear
      @forward_edges = nil
      @backward_edges = nil
    end

    def load(fixtures = nil)
      fixtures ||= self.fixtures or raise "No flock fixtures specified. either pass fixtures to load, or set Flock::MockService.fixtures."

      clear

      fixtures.each do |fixture|
        file, graph, source, dest = fixture.values_at(:file, :graph, :source, :destination)

        YAML::load(ERB.new(File.open(file, 'r').read).result(binding)).sort.each do |key, row|
          add(row[source], graph, row[dest])
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
        graph, source = term.graph_id, term.source_id
        dest = term.destination_ids && term.destination_ids.unpack('Q*')

        source, dest = dest, source unless term.is_forward

        self.send(EXEC_OPS[operation.operation_type], source, graph, dest)
      end
    end

    def select(select_operations, page)
      iterate(select_query(select_operations), page)
    end

    def contains(source, graph, dest)
      forward_edges[graph][:normal][source].include?(dest)
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
          source = term.is_forward ? forward_edges : backward_edges
          data = source[term.graph_id][:normal][term.source_id]
          stack.push(term.destination_ids ? (term.destination_ids.unpack('Q*') & data) : data)
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

    def iterate(data, page)
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

      result = Flock::Results.new
      result.ids = Array(rv).pack("Q*")
      result.next_cursor = next_cursor
      result.prev_cursor = prev_cursor
      result
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


    [:forward_edges, :backward_edges].each do |name|
      class_eval("def #{name}; @#{name} ||= new_edges_hash end")
    end

    def new_edges_hash
      Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = Hash.new { |h2,k2| h2[k2] = [] } } }
    end

    def add_row(store, source, dest)
      (store[source] << dest).uniq!
    end

    def add_edge(source, graph, dest, state)
      add_row(forward_edges[graph][state], source, dest)
      add_row(backward_edges[graph][state], dest, source)
      [source, graph, dest]
    end

    def remove_row(store, source, dest)
      store[source].delete(dest).tap do
        store.delete(source) if store[source].empty?
      end
    end

    def remove_edge(source, graph, dest, state)
      forward = remove_row(forward_edges[graph][state], source, dest)
      backward = remove_row(backward_edges[graph][state], dest, source)

      [source, graph, dest] if forward and backward
    end

    def remove_node(source, graph, dest, state)
      raise unless source or dest

      sources, dests = Array(source), Array(dest)

      sources = dests.map{|dest| backward_edges[graph][state][dest] }.inject([]) {|a,b| a.concat b } if sources.empty?
      dests = sources.map{|source| forward_edges[graph][state][source] }.inject([]) {|a,b| a.concat b } if dests.empty?

      [].tap do |deleted|
        sources.each {|s| dests.each {|d| deleted << remove_edge(s, graph, d, state) } }
      end.compact
    end

    def unarchive_node(source, graph, dest)
      remove_node(source, graph, dest, :archived).tap do |deleted|
        deleted.each {|source, graph, dest| add_edge(source, graph, dest, :normal) }
      end
    end

    # actual graph helpers

    def add(source, graph, dest)
      if source.nil? or dest.nil?
        unarchive_node(source, graph, dest)
      else
        sources, dests = Array(source), Array(dest)

        sources.each do |s|
          dests.each do |d|
            add_edge(s, graph, d, :normal)
            remove_edge(s, graph, d, :archived)
          end
        end
      end
    end

    def remove(source, graph, dest)
      remove_node(source, graph, dest, :archived)
      remove_node(source, graph, dest, :normal)
    end

    def negate(source, graph, dest)
      remove_node(source, graph, dest, :normal).tap do |negated|
        negated.each {|source, graph, dest| add_edge(source, graph, dest, :negate) }
      end
    end

    def archive(source, graph, dest)
      remove_node(source, graph, dest, :normal).tap do |deleted|
        deleted.each {|source, graph, dest| add_edge(source, graph, dest, :archived) }
      end
    end
  end
end
