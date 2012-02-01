# Keep track of deltas and tombstones for an array of data

A cache that keeps track of deltas and tombstones for an array of data. Deltas and tombstones can be retrieved from the cache using a last-modified timestamp.

## Configuration

### Redis

Connection

    DeltaCache.connection = Redis.new(:host => "your-host-ip")

### Cassandra

Setup Cassandra Keyspaces and Column Families

    create keyspace DeltaCache;
    use DeltaCache;
    create column family Cache;
    create column family Deltas;

    create keyspace DeltaCacheTest;
    use DeltaCacheTest;
    create column family Cache;
    create column family Deltas;

Connection

    DeltaCache.connection = Cassandra.new('DeltaCache')

### Namespace

    DeltaCache.cache_name = "your-cache-namespace"

### Logger

    DeltaCache.logger = Logger.new(STDOUT, Logger::DEBUG)

See emamples directory for more details.