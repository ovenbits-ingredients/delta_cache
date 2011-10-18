module RedisDB

  def self.info_key(id)
    "bl:info_cache:info:#{id}"
  end

  def self.deleted_info_key(id)
    "bl:info_cache:deleted_info:#{id}"
  end

  # set parent key that holds the data
  def self.set(data)
    data = data.to_json
    cache_key = Digest::SHA1.hexdigest(data)
    REDIS_FRIEND_CACHE.set(cache_key, data)
    cache_key
  end

  # add key to a set
  def self.add(key, timestamp, value)
    REDIS_FRIEND_CACHE.zadd(key, timestamp.to_i, value)
  end

  # remove key from a set
  def self.rem(key, value)
    REDIS_FRIEND_CACHE.zrem(key, value)
  end

  # get a list of keys
  def self.get(keys)
    REDIS_FRIEND_CACHE.mget(*keys)
  end

  # get members from a set in reverse order
  def self.get_rev_range(key, end_pos, start_pos)
    REDIS_FRIEND_CACHE.zrevrangebyscore(key, end_pos.to_i, start_pos.to_i)
  end

  # get the 'score' of the member in a set
  def self.get_timestamp(key, value)
    score = REDIS_FRIEND_CACHE.zscore(key, value)
    Time.at(score.to_i).utc
  end

  # delete a key
  def self.del(key)
    REDIS_FRIEND_CACHE.del(key)
  end

  # does a key exist
  def self.exists(key)
    REDIS_FRIEND_CACHE.exists(key)
  end

end
