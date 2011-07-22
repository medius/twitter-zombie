class TwitterWrapper
   attr_reader :tokens
   
   def initialize(config)
     @config = config
     @tokens = YAML::load_file @config
     @callback_url = @tokens['callback_urls'][Rails.env]
     @auth = Twitter::OAuth.new(@tokens['consumer_key'], @tokens['consumer_secret'])

   end
   
   def request_tokens
     @request_token = @auth.request_token :oauth_callback => @callback_url
     [@request_token.token, @request_token.secret]
   end
   
   def authorize_url
     @request_token.authorize_url(:oauth_callback => @callback_url)
   end
   
   def auth(rtoken, rsecret, verifier)
     @auth.authorize_from_request(rtoken, rsecret, verifier)
     [@auth.access_token.token, @auth.access_token.secret]
   end
   
   def get_twitter(atoken, asecret)
     @auth.authorize_from_access(atoken, asecret)
     twitter = Twitter::Base.new @auth
     twitter.home_timeline(:count => 1)
     twitter
   end
end