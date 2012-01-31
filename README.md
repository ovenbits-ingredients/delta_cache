# Keep track of deltas and tombstones

Store data in a cache that keeps track of deltas and tombstones. Retrieve changes from a given timestamp.

## Configuration

Setup Cassandra Keyspaces and Column Families

    create keyspace TimeCache;
    use TimeCache;
    create column family Cache;
    create column family Deltas;

    create keyspace TimeCacheTest;
    use TimeCacheTest;
    create column family Cache;
    create column family Deltas;

## Usage

### Connections

Redis

    DeltaCache::RedisDB.connection = Redis.new(:host => "127.0.0.1")
    DeltaCache.db = DeltaCache::RedisDB.new

Cassandra

    DeltaCache::CassandraDB.connection = Cassandra.new('DeltaCache')
    DeltaCache::CassandraDB.logger = Logger.new(STDOUT, Logger::DEBUG)
    DeltaCache.db = DeltaCache::CassandraDB.new

