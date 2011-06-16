class Flock::Client

  attr_accessor :graphs
  attr_reader :service

  class << self
    def service_class; Flock.default_service_class ||= Flock::Service end
  end

  # takes arguments a list of servers and an options hash to pass to the default service_class,
  # or a service itself
  def initialize(servers = nil, options = {})
    options = options.dup
    if graphs = (options.delete(:graphs) || Flock.graphs)
      @graphs = graphs
    end

    @service =
      if servers.nil? or servers.is_a? Array or servers.is_a? String
        self.class.service_class.new(servers, options)
      else
        servers
      end
  end


  # local results cache

  def cache_locally
    @cache = {}
    yield
  ensure
    @cache = nil
  end

  def _cache(op, query)
    return yield unless @cache
    @cache[[op, query]] ||= yield
  end

  def _cache_clear
    @cache = {} if @cache
  end

  # queries

  def multi(&block)
    select_operations = Flock::SelectOperations.new(self)
    yield select_operations
    select_operations
  end

  def select(*query)
    query = query.first if query.size == 1 # supports deprecated API [[1, 2, 3]]
    Flock::SimpleOperation.new(self, Flock::QueryTerm.new(query, graphs))
  end

  def get(source, graph, destination)
    raise ArgumentError unless source.is_a?(Fixnum) && destination.is_a?(Fixnum)

    select(source, graph, destination, [:positive, :removed, :negative, :archived]).edges.paginate(1).current_page.first
  end

  def contains(*query)
    query = Flock::QueryTerm.new(query, graphs).unapply[0, 3]
    _cache :contains, query do
      service.contains(*query)
    end
  end

  def size(*query)
    _cache :size, query do
      select(*query).size
    end
  end
  alias count size


  # edge manipulation

  def update(method, source_id, graph, destination_id, *args)
    priority, execute_at, position = process_args(args)

    _cache_clear
    ops = current_transaction || Flock::ExecuteOperations.new(@service, priority, execute_at)
    ops.send(method, *(_query_args([source_id, graph, destination_id])[0, 3] << position))
    ops.apply unless in_transaction?
  end

  Flock::Edges::ExecuteOperationType::VALUE_MAP.values.each do |method|
    method = method.downcase
    class_eval "def #{method}(*args); update(#{method.inspect}, *args) end", __FILE__, __LINE__
  end

  alias unarchive add

  def transaction(*args, &block)
    priority, execute_at, _ = process_args(args)
    new_transaction = !in_transaction?

    ops =
      if new_transaction
        Thread.current[:edge_transaction] = Flock::ExecuteOperations.new(@service, priority, execute_at)
      else
        current_transaction
      end

    result = yield self
    ops.apply if new_transaction
    result

  ensure
    Thread.current[:edge_transaction] = nil if new_transaction
  end

  def current_transaction
    Thread.current[:edge_transaction]
  end

  def in_transaction?
    !!Thread.current[:edge_transaction]
  end

  private
  def _lookup_graph(key)
    if @graphs.nil? or key.is_a? Integer
      key
    else
      @graphs[key] or raise UnknownGraphError.new(key)
    end
  end

  def _lookup_states(states)
    states = states.flatten.compact.map do |s|
      if s.is_a? Integer
        s
      else
        STATES[s] or raise UnknownStateError.new(s)
      end
    end
  end

  def _query_args(args)
    source, graph, destination, *states = *((args.length == 1) ? args.first : args)
    [_node_arg(source), _lookup_graph(graph), _node_arg(destination), _lookup_states(states)]
  end

  def _node_arg(node)
    return node.map {|n| n.to_i if n } if node.respond_to? :map
    node.to_i if node
  end

  def process_args(args)
    options = args.last.is_a?(Hash) ? args.pop : nil
    [args.first || Flock::Priority::High, options && options[:execute_at], options && options[:position]]
  end
end
