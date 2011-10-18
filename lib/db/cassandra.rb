# Stores friend cache data in a Cassandra keyspace. The advantage here is
# the cache can grow larger than the memory on one machine. The disadvantage
# is that you have to set up multiple machines and make some decisions about
# acceptable thresholds around consistency and atomicity.
#
# This module requires initialization, like so:
#
#   TimeCache::CassandraDB.connection = Cassandra.new('TimeCache')
#   TimeCache::CassandraDB.logger = Logger.new(STDOUT, Logger::DEBUG)
#
# You only need to set the logger if you need to debug.
#
# ## Storage
#
# This adapter uses two column families: `:Cache` and `:Deltas`. 
#
# The `:Cache` CF stores each cached object as a JSON blob. Each row is keyed
# by the SHA1 hash of the blob. The blob itself is stored in a column named
# `blob`. These rows won't ever get too wide, so this CF is a good candidate
# for row caching by Cassandra.
#
# The `:Deltas` CF stores changes to objects cached for each user. There are
# two rows per user; one tracks newly cached objects and the other tracks
# cached objects that have been removed. Each row contains a pair of columns
# per cached object. One maps a timestamp to a cached object and is used for
# caching the most recent changes to a user's cached objects. The other maps
# cached objects back to a timestamp and is used to find delta entries to
# remove if a cached object is marked as removed.
module CassandraDB
  
  MAX_DELTAS = 10_000
  
  # The Cassandra driver object to use.
  mattr_accessor :connection

  # A logger, for logging.
  mattr_accessor :logger

  # Store a cached object.
  def self.set(data)
    data = data.to_json
    cache_key = Digest::SHA1.hexdigest(data)

    log("insert :Cache, #{cache_key} -> {'blob' => #{data.inspect}}")
    connection.insert(:Cache, cache_key, { "blob" => data })
    cache_key
  end

  # Add a cached object to a delta timeline.
  def self.add(key, timestamp, value)
    columns = { timestamp_name(timestamp) => value, cache_name(value) => timestamp.to_f.to_s }

    log("insert :Deltas, #{key} -> #{columns.inspect}")
    connection.insert(:Deltas, key, columns)
  end

  # Remove a cached object from a delta timeline.
  def self.rem(key, value)
    log("get :Deltas, #{key}, #{cache_name(value)}")
    timestamp = connection.get(:Deltas, key, cache_name(value))

    log("remove :Deltas, #{key} -> #{timestamp_name(timestamp)}")
    connection.remove(:Deltas, key, timestamp_name(timestamp))

    log("remove :Deltas, #{key} -> #{cache_name(value)}")
    connection.remove(:Deltas, key, cache_name(value))
  end

  # Fetch multiple cached objects.
  def self.get(keys)
    log("get :Cache, #{keys.inspect}")
    connection.multi_get(:Cache, Array(keys)).values.map { |v| v['blob'] }
  end

  # Find all the cached objects referenced by a delta timeline.
  def self.get_rev_range(key, most_recent, last_modified)
    log("get :Deltas, #{key}, :reversed => true, :start => #{timestamp_name(most_recent)}, :finish => #{timestamp_name(last_modified)}")
    connection.get(:Deltas, key, :reversed => true, :start => timestamp_name(most_recent), :finish => timestamp_name(last_modified), :count => MAX_DELTAS).values
  end

  # Get a mapping of cached objects to delta timestamps for a given user.
  def self.get_timestamp(key, value)
    log("get :Deltas, #{key}, #{cache_name(value)}")
    score = connection.get(:Deltas, key, cache_name(value))
    Time.at(score.to_f).utc
  end

  # Remove an object from the cache.
  def self.del(key)
    log("remove :Cache, #{key}")
    connection.remove(:Cache, key)
  end

  # Check if a delta cache exists for a user.
  def self.exists(key)
    log("exists? :Deltas, #{key}")
    connection.exists?(:Deltas, key)
  end

  # Given a user ID, generate a key into `:Deltas` for cached objects.
  def self.info_key(id)
    ["cache", id].join(":")
  end

  # Given a user ID, generate a key into `:Deltas` for deleted cache objects.
  def self.deleted_info_key(id)
    ["deleted", id].join(":")
  end

  # Given a timestamp, generate a column name for use in range queries on `:Deltas`.
  def self.timestamp_name(timestamp)
    ["ts", timestamp.to_f].join(":")
  end

  # Given the SHA1 for a cached object, generate a key into `:Cache`.
  def self.cache_name(value)
    ["cache", value].join(":")
  end

  # Private: Log a message, if a logger is set.
  def self.log(msg)
    return if logger.nil?
    logger.debug(msg)
  end

end
