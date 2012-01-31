class DeltaCache

  require 'redis'
  require 'cassandra'

  class << self; attr_accessor :db, :logger end

  attr_accessor :id, :options

  def initialize(id, options={})
    self.id = id
    self.options = options
  end

  def info_key
    db.info_key(id)
  end

  def deleted_info_key
    db.deleted_info_key(id)
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
    # always pull ever record when updating the cache
    options.delete(:last_modified)

    cache_new(info)
    # stores tombstones for deleted records
    cache_deleted(info)

    return true
  end

  def cache_new(info)
    new_info = (info - get_info(false))
    new_info.each do |info|
      info_id = set_info(info)
      db.rem(deleted_info_key, info_id)
      db.add(info_key, timestamp, info_id)
    end
  end

  def cache_deleted(info)
    deleted_info = (get_info(false) - info)
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
    db.set(info, options[:cache_key])
  end

  def get_info(show_deleted_flag=true)
    return [] unless exists?

    last_modified = options[:last_modified] ? timestamp(options[:last_modified]) : Time.at(0)
    info = []

    info_ids = db.get_rev_range(info_key, timestamp, last_modified + 1)
    if info_ids.any?
      info += db.get(info_ids).compact.map do |f|
        hash = JSON.parse(f)
        hash.merge!(:deleted => false) if show_deleted_flag
        hash
      end
    end

    if last_modified.to_i > 0
      info_ids = db.get_rev_range(deleted_info_key, timestamp, last_modified + 1)
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

  def db
    @db ||= DeltaCache.db
  end

  # A logger, for logging.
  def logger
    @logger ||= DeltaCache.logger
  end

end
