class Flock::Client

  # symbol => state_id map
  STATES = Flock::Edges::EdgeState::VALUE_MAP.inject({}) do |states, (id, name)|
    states.update name.downcase.to_sym => id
  end.freeze

  attr_accessor :graphs
  attr_reader :service

  class << self
    def service_class; Flock.default_service_class ||= Flock::Service end
  end

  # takes arguments a list of servers and an options hash to pass to the default service_class,
  # or a service itself
  def initialize(servers = nil, options = {})
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

  def select(*query)
    Flock::SimpleOperation.new(self, _query_args(query))
  end

  def contains(*query)
    query = _query_args(query)[0, 3]
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

  def update(method, source_id, graph, destination_id, priority = Flock::Priority::High, options = {})
    execute_at = options.delete(:execute_at)
    position = options.delete(:position)

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

  def transaction(priority = Flock::Priority::High, options = {}, &block)
    execute_at = options.delete(:execute_at)
    position = options.delete(:position)

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


  # graph name lookup utility methods

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
end
