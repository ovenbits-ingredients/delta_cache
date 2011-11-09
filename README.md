# Setup Cassandra Keyspaces and Column Families
create keyspace TimeCache;
use TimeCache;
create column family Cache;
create column family Deltas;

create keyspace TimeCacheTest;
use TimeCacheTest;
create column family Cache;
create column family Deltas;
