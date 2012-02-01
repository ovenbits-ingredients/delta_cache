require 'rubygems'
require 'redis'
require 'json'

require File.expand_path('../../lib/delta_cache.rb')

DeltaCache.connection = Redis.new(:host => "127.0.0.1")
DeltaCache.cache_name = "notifications"

class Notifications

  attr_accessor :cache

  def initialize(cache_id)
    self.cache = DeltaCache::Cache.new(cache_id)

    ## flush and initialize cache
    cache.flush!

    puts "\nInitializing cache..."
    notifications = [
      {:name => "John", :message => "Be my friend."},
    ]
    update_and_print(notifications)
  end

  def add_to_cache
    puts "\nAdding Steve and Bill to cache..."

    lm = cache.get_last_modified
    puts "\n    Deltas since: #{lm}"
    notifications = [
      {:name => "John", :message => "Be my friend."},
      {:name => "Steve", :message => "Be my friend."},
      {:name => "Bill", :message => "Be my friend."}
    ]

    update_and_print(notifications)
  end

  def delete_from_cache
    puts "\nDeleting John from cache..."

    lm = cache.get_last_modified
    puts "\n    Tombstones since: #{lm}"
    notifications = [
      {:name => "Steve", :message => "Be my friend."},
      {:name => "Bill", :message => "Be my friend."}
    ]

    update_and_print(notifications)
  end

  def update_and_print(data)
    lm = cache.get_last_modified
    cache.update(data)
    puts "    " + cache.get_info(lm).inspect
  end

end

n = Notifications.new(1)
sleep 2

n.add_to_cache
sleep 2

n.delete_from_cache
