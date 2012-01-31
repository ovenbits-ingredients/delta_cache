require 'rack'
require './facebook'

class Callback

  attr_accessor :last_modified

  def call(env)
    init(env)
    puts env.inspect
    puts env["rack.input"].input.inspect
    puts @req.inspect
    puts @req.form_data?
    puts @req.params.inspect

    if is_valid_request?

      if is_challenge_request?
        [200, {'Content-Type' => 'text/plain'}, [@params["hub.challenge"]]]

      else
        changes = @params["entry"]
        changes.each do |entry|

          if is_valid_change?(entry)
            fb_id = Integer(entry["uid"])

            # update cache
            friends_info = Facebook.get_friends(fb_id)
            DeltaCache.new(fb_id, :cache_key => "facebook_#{fb_id}").update(friends_info)

            # show changes
            puts DeltaCache.new(
              fb_id, :last_modified => self.last_modified
            ).get_info

            # store last modified timestamp
            self.last_modified = DeltaCache.new(fb_id).get_last_modified
          end
        end

        [200, {'Content-Type' => 'text/plain'}, []]
      end

    else
      [404, {'Content-Type' => 'text/plain'}, []]

    end
  end

  def init(env)
    @req = Rack::Request.new(env)
    @params = @req.params if @req
  end

  def is_valid_request?
    @req && @params
  end

  def is_challenge_request?
    return false if @params["hub.mode"].nil? || @params["hub.mode"].empty?
    return false if @params["hub.challenge"].nil? || @params["hub.challenge"].empty?
    return false if @params["hub.verify_token"].nil? || (token = @params["hub.verify_token"]).empty?
    return FACEBOOK_CONFIG[:subscription_token] == token
  end

  def is_valid_change?(entry)
    fb_id = Integer(entry["uid"])
    fields = Array(entry["changed_fields"])

    return false if fb_id.empty?
    return false if fields.empty?
    return fields.include?("friends")
  end

end
