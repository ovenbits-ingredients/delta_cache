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
require 'fb_graph'
require 'redis'

require '../../lib/delta_cache'

FACEBOOK_CONFIG = {
  :app_id => "your-app-id",
  :access_token => "your-fb-access-token",
  :subscription_callback_url => "http://your-public-ip/",
  :subscription_token => "any-token-to-validate-the-fb-request"
}

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
    FbGraph::User.fetch(fb_id, :access_token => FACEBOOK_CONFIG[:access_token])
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
