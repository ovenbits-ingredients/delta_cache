class DeltaCache::RedisDB

  attr_accessor :cache_id

  def initialize(cache_id)
    self.cache_id = cache_id
  end

  def connection
    DeltaCache.connection
  end

  def cache_name
    DeltaCache.cache_name
  end

  def info_key
    [
      "delta_cache",
      "info",
      cache_name,
      cache_id
      ].join(":")
  end

  def deleted_info_key
    [
      "delta_cache",
      "deleted_info",
      cache_name,
      cache_id
      ].join(":")
  end

  # set parent key that holds the data
  def set(data)
    data = data.to_json
    cache_key = Digest::SHA1.hexdigest(data)
    connection.set(cache_key, data)
    cache_key
  end

  # add key to a set
  def add(key, timestamp, value)
    connection.zadd(key, timestamp.to_i, value)
  end

  # remove key from a set
  def rem(key, value)
    connection.zrem(key, value)
  end

  # get a list of keys
  def get(keys)
    connection.mget(*keys)
  end

  # get members from a set in reverse order
  def get_rev_range(key, end_pos, start_pos)
    connection.zrevrangebyscore(key, end_pos.to_i, start_pos.to_i)
  end

  # get the 'score' of the member in a set
  def get_timestamp(key, value)
    score = connection.zscore(key, value)
    Time.at(score.to_i).utc
  end

  # delete a key
  def del(key)
    connection.del(key)
  end

  # does a key exist
  def exists(key)
    connection.exists(key)
  end

end
