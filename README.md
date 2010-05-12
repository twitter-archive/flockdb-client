FlockDB ruby client

FlockDB is a distributed graph database capable of storing millions of
nodes, billions of edges, and handling tens of thousands of operations
per second. Interact with it in ruby with this client.


INSTALLATION
------------

    gem install flockdb

FlockDB depends on thrift and thrift_client, which will install as
part of the gem's dependencies. Note that thrift has a native C
extension which it will need to compile.


USAGE
-----

Instantiate a client:

    flockdb = Flock.new 'localhost:7915, :graphs => { :follows => 1, :blocks => 2 }

Flock.new is a convenience shortcut for Flock::Client.new. Flock.new
expects a list (or a single) servers as the first argument, and an
options hash. Flock::Client.new takes the same options as ThriftClient
for configuring the raw thrift client, as well as :graphs for mapping
ruby symbols to the corresponding graph ids. See [thrift_client's
documentation](http://github.com/fauna/thrift_client) for information
on the other options it takes.

Edge manipulation:

    flockdb.add(1, :follows, 2)
    flockdb.remove(1, :blocks, 2)

Perform a query:

    flockdb.select(1, :follows, nil).to_a

The client supports a rich query api to build up complex set operations:

    flockdb.select(nil, :follows, 1).difference(flockdb.select(1, :follows, nil).intersect(2, :follows, nil)).to_a


CONTRIBUTORS
------------

Nick Kallen
Matt Freels
Rael Dornfest
Tina Huang


LICENSE
-------

Copyright (C) 2010 Twitter, Inc.

This work is licensed under the Apache License, Version 2.0. See LICENSE for details.
