module DeltaCache

  require 'time'
  require 'digest'

  require 'delta_cache/db/redis'
  require 'delta_cache/db/cassandra'

  class << self
    attr_accessor :connection, :logger, :cache_name
  end

  class Cache

    attr_accessor :db, :cache_id

    def initialize(cache_id)
      self.cache_id = cache_id

      raise "DeltaCache.connection is not defined." unless DeltaCache.connection
      raise "DeltaCache.cache_name is not defined." unless DeltaCache.cache_name

      class_name = DeltaCache.connection.class.name
      if class_name =~ /redis/i
        self.db = DeltaCache::RedisDB.new(cache_id)
      elsif class_name =~ /cassandra/i
        self.db = DeltaCache::CassandraDB.new(cache_id)
      end
    end

    def info_key
      db.info_key
    end

    def deleted_info_key
      db.deleted_info_key
    end

    def exists?
      db.exists(info_key)
    end

    # this will remove all cache for the given id
    def flush!
      db.del(info_key)
      db.del(deleted_info_key)
    end

    def update(info)
      cache_new(info)
      # stores tombstones for deleted records
      cache_deleted(info)

      return true
    end

    def cache_new(info)
      new_info = (info - get_info(nil, false))
      new_info.each do |info|
        info_id = set_info(info)
        db.rem(deleted_info_key, info_id)
        db.add(info_key, timestamp, info_id)
      end
    end

    def cache_deleted(info)
      deleted_info = (get_info(nil, false) - info)
      deleted_info.each do |info|
        info_id = set_info(info)
        db.rem(info_key, info_id)
        db.add(deleted_info_key, timestamp, info_id)
      end
    end

    def timestamp(time=nil)
      Time.parse((time || Time.now).to_s).utc
    end

    def set_info(info)
      db.set(info)
    end

    def get_info(last_modified=nil, show_deleted_flag=true)
      return [] unless exists?

      last_modified_time = if last_modified.nil?
        Time.at(0)
      else
        timestamp(last_modified)
      end

      info = []

      info_ids = db.get_rev_range(info_key, timestamp, last_modified_time + 1)
      if info_ids.any?
        info += db.get(info_ids).compact.map do |f|
          hash = JSON.parse(f)
          hash.merge!(:deleted => false) if show_deleted_flag
          hash
        end
      end

      if last_modified_time.to_i > 0
        info_ids = db.get_rev_range(deleted_info_key, timestamp, last_modified_time + 1)
        if info_ids.any?
          info += db.get(info_ids).compact.map do |f|
            hash = JSON.parse(f)
            hash.merge!(:deleted => true) if show_deleted_flag
            hash
          end
        end
      end

      info.map do |hash|
        new_hash = Hash.new
        hash.each do |k, v|
          new_hash[k.to_sym] = v
        end
        new_hash
      end
    end

    def get_last_modified
      info_ids = db.get_rev_range(info_key, timestamp, Time.at(0))
      deleted_info_ids = db.get_rev_range(deleted_info_key, timestamp, Time.at(0))

      last_modified = [ db.get_timestamp(info_key, info_ids.first),
        db.get_timestamp(deleted_info_key, deleted_info_ids.first) ].compact
      return Time.now.utc.httpdate unless last_modified.any?

      Time.at(last_modified.max.to_i).utc.httpdate
    end

  end

end
