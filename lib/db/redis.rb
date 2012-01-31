class TimeCache::RedisDB

  class << self; attr_accessor :connection end

  def connection
    @connection ||= TimeCache::RedisDB.connection
  end

  def info_key(id)
    "delta_cache:info_cache:info:#{id}"
  end

  def deleted_info_key(id)
    "delta_cache:info_cache:deleted_info:#{id}"
  end

  # set parent key that holds the data
  def set(data, key=nil)
    data = data.to_json
    cache_key = (key || Digest::SHA1.hexdigest(data))
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
