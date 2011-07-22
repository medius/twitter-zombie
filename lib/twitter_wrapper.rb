class TwitterWrapper
   attr_reader :tokens
   
   def initialize(config)
     # File.join(Rails.root, 'config', 'twitter.yml')
     @config = config
     @tokens = YAML::load_file @config
     @callback_url = @tokens['callback_urls'][Rails.env]
     #puts "CB:#{@callback_url}"
     @auth = Twitter::OAuth.new('xcQnowmpUKU7KTWjiyg','fuenh1AbUpKSrFTMUvRO4w9tKPE9w5cUgRnf7QNgE')
     #@auth = OAuth::Consumer.new('xcQnowmpUKU7KTWjiyg', 'fuenh1AbUpKSrFTMUvRO4w9tKPE9w5cUgRnf7QNgE',
    #                                   {:site => "http://api.twitter.com"})
   end
   
   def request_tokens
     puts "CallbackURL:#{@callback_url} Auth:#{@auth}"
     @request_token = @auth.request_token :oauth_callback => @callback_url
     puts "Tokens:#{@request_token.token} #{@request_token.secret}"
     [@request_token.token, @request_token.secret]
   end
   
   def authorize_url
     @request_token.authorize_url(:oauth_callback => @callback_url)
   end
   
   def auth(rtoken, rsecret, verifier)
     puts "Auth data:#{rtoken} #{rsecret} #{verifier}"
     @auth.authorize_from_request(rtoken, rsecret, verifier)
     puts "Access token: #{@auth.access_token.token} Access secret: #{@auth.access_token.secret}"
     [@auth.access_token.token, @auth.access_token.secret]
   end
   
   def get_twitter(atoken, asecret)
     @auth.authorize_from_access(atoken, asecret)
     puts "Auth in get_twitter: #{@auth}"
     twitter = Twitter::Base.new @auth
     puts "Got twitter client with auth"
     twitter.home_timeline(:count => 1)
     twitter
   end
end