####
# Enable/disable Facebook subscriptions for a Facebook application
# so you will be notified of any changes to the users who have
# authorized the given Facebook app.
#
# Usage:
# Configure the FACEBOOK_CONFIG hash with the app information
# and then execute the ruby script.
#
####

require 'net/http'
require 'uri'

require 'rubygems'
require 'hyper_graph'
require 'redis'

require '../lib/delta_cache'

FACEBOOK_CONFIG = {
  :app_id => 115997361652,
  :access_token => "115997361652|u4x6su1ZTv8NkgmwK0WgBJ4Yvwg",
  :subscription_callback_url => "http://24.153.226.51:9000/",
  :subscription_token => "74bfdac24ffb6f9305ef78cf0ca3671b0d9b615a"
}

## Redis
DeltaCache::RedisDB.connection = Redis.new(
  :host => "127.0.0.1"
)
DeltaCache.db = DeltaCache::RedisDB.new

## Cassandra
# DeltaCache::CassandraDB.connection = Cassandra.new(
#   'DeltaCache',
#   '127.0.0.1:9160',
#   :retries => 3
# )
# DeltaCache.db = DeltaCache::CassandraDB.new

## Logging
# DeltaCache.logger = Logger.new(STDOUT, Logger::DEBUG)

class Facebook

  def self.subscribe!
    uri = URI.parse("https://graph.facebook.com/#{FACEBOOK_CONFIG[:app_id]}/subscriptions")
    form_data = {
      :object => "user",
      :fields => "name,friends",
      :access_token => FACEBOOK_CONFIG[:access_token],
      :callback_url => FACEBOOK_CONFIG[:subscription_callback_url],
      :verify_token => FACEBOOK_CONFIG[:subscription_token]
    }

    HTTP.new(uri).post(form_data)
  end

  def self.unsubscribe!
    uri = URI.parse("https://graph.facebook.com/#{FACEBOOK_CONFIG[:app_id]}/subscriptions")
    form_data = {
      :object => "user",
      :access_token => FACEBOOK_CONFIG[:access_token]
    }

    HTTP.new(uri).delete(form_data)
  end

  def self.get_friends(fb_id)
    friends = HyperGraph.get("#{fb_id}/friends", :access_token => FACEBOOK_CONFIG[:access_token])

    return friends
  end

  class HTTP

    attr_accessor :uri, :http

    def initialize(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 120

      self.uri = uri
      self.http = http
    end

    def post(form_data)
      request = Net::HTTP::Post.new(self.uri.request_uri)
      request.set_form_data(form_data)
      response = self.http.request(request)

      puts "\nForm Data"
      puts form_data.inspect
      puts "--"

      puts "\nResponse"
      puts response
      puts "--"
    end

    def delete(form_data)
      request = Net::HTTP::Delete.new(self.uri.request_uri)
      request.set_form_data(form_data)
      response = self.http.request(request)

      puts "\nResponse"
      puts response
      puts "--"
    end

  end

end
