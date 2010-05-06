class Flock::Client

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
    query = _query_args(query)
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

  def update(method, source_id, graph, destination_id, priority = Flock::Priority::High)
    _cache_clear
    ops = current_transaction || Flock::ExecuteOperations.new(@service, priority)
    ops.send(method, *_query_args([source_id, graph, destination_id]))
    ops.apply unless in_transaction?
  end

  [:add, :remove, :archive, :unarchive, :negate].each do |method|
    class_eval "def #{method}(*args); update(#{method.inspect}, *args) end", __FILE__, __LINE__
  end

  def transaction(priority = Flock::Priority::High, &block)
    new_transaction = !in_transaction?

    ops =
      if new_transaction
        Thread.current[:edge_transaction] = Flock::ExecuteOperations.new(@service, priority)
      else
        current_transaction
      end

    result = yield self if block.arity == 1
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

  def _query_args(args)
    source, graph, destination = *((args.length == 1) ? args.first : args)
    [_node_arg(source), _lookup_graph(graph), _node_arg(destination)]
  end

  def _node_arg(node)
    return node.map {|n| n.to_i if n } if node.respond_to? :map
    node.to_i if node
  end
end
