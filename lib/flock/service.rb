module Flock
  class Service < ThriftClient
    DEFAULTS = { :transport_wrapper => Thrift::BufferedTransport }

    def initialize(servers = nil, options = {})
      if servers.nil? or servers.empty?
        STDERR.puts "No servers specified, using 127.0.0.1:7915"
        servers = ['127.0.0.1:7915']
      else
        servers = Array(servers)
      end

      super(Edges::Client, servers, DEFAULTS.merge(options))
    end
  end
end
