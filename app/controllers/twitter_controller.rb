class TwitterController < ApplicationController
  include TwitterHelper
  respond_to :html, :json, :js
      
  def index
    begin            
      @twitter = get_twitter

      # Get the basic user information
      info = get_user_info(@twitter)
      @user_name = get_user_name(info)
      @screen_name = get_user_screen_name(info)
      @friends_count = get_user_friends_count(info)
      
      # Get the friends information
      response = @twitter.get(api_url("statuses/friends.json"))
      @friends_info = JSON.parse(response.body)      
      @friends = get_screen_names(@friends_info).paginate(:per_page => 20, :page => params[:page])
      
    rescue  Exception => err
      logger.error("Index action failed: #{err.message}")
      session[:atoken] = nil
      session[:asecret] = nil
    end
    
  end
  
  def signin
    begin
      twitter_auth
    rescue
      flash[:error] = 'Error while connecting with Twitter. Please try again.'
      redirect_to :action => :index
    end
  end
  
  def signout
    session[:atoken] = nil
    session[:asecret] = nil
    redirect_to root_url, :notice => "Signed out successfully."
  end
  
  def callback
    begin
      @request_token = session[:request_token]
      @access_token = @request_token.get_access_token
      session[:atoken] = @access_token.token
      session[:asecret] = @access_token.secret
  
      flash[:notice] = "Successfully signed in with Twitter."
    rescue
      flash[:error] = 'You were not authorized by Twitter!'
    end
    redirect_to :action => :index
  end
  
  # Mass follow
  def follow
    begin
      @twitter = get_twitter 
      params[:result_ids].each do |result_id|
        begin
          @data = follow_user(@twitter, result_id, true)
        rescue
          flash[:error] = "Error in following #{result_id}"
        end
      end
      info = get_user_info(@twitter)
      @friends_count = get_user_friends_count(info)
    rescue
      flash[:error] = "Error in following these users! Please try again."
    end
    redirect_to root_url, :notice => "Follow complete."
  end
  
  # Mass unfollow
  def unfollow
    begin
      @twitter = get_twitter      
      params[:friend_ids].each do |friend_id|
        begin
          unfollow_user(@twitter, friend_id)
        rescue
          flash[:error] = "Error in unfollowing #{friend_id}"
        end
      end
      info = get_user_info(@twitter)
      @friends_count = get_user_friends_count(info)
    rescue
      flash[:error] = "Error sending the unfollowing! Please try again."
    end
    redirect_to root_url, :notice => "Unfollow complete."
  end
  
  def search
    begin
      @twitter = get_twitter
      @results = get_screen_names(user_search(@twitter, params[:search]))
      respond_with(@results)
    rescue
      flash[:error] = "Error in searching Twitter"
    end
  end
  
  private
  
  # Authorize with Twitter
  def twitter_auth
    # Get the correct callback url based on the Rails environment
    @callback_url = TOKENS['callback_urls'][Rails.env]
    
    # Initialize a Twitter consumer
    @consumer = get_consumer
    
    # Get the request token and save it 
    @request_token = @consumer.get_request_token(:oauth_callback => @callback_url)
    session[:request_token] = @request_token
    
    # Redirect the user to the Twitter website for authentication
    redirect_to @request_token.authorize_url(:oauth_callback => @callback_url)
  end
  
  def get_twitter
    consumer = get_consumer
    @access_token = OAuth::AccessToken.new(consumer, session[:atoken], session[:asecret])
  end

  # Initialize Twitter consumer
  def get_consumer
    @consumer = OAuth::Consumer.new(TOKENS['consumer_key'], TOKENS['consumer_secret'], 
                                  { :site => "http://api.twitter.com",
                                    :authorize_path => '/oauth/authenticate' })
  end     
  
  def get_screen_names(users)
    screen_names = []
    users.each do |user|
      screen_names.push(get_user_screen_name(user))
    end
    return screen_names
  end
  
  #########################################################################
  # Twitter API Calls
  #########################################################################
  # Construct the full API URL
  def api_url(path)
    "http://api.twitter.com/1/" + path
  end
  
  # Get the user information
  def get_user_info(atoken)
    begin
      response = atoken.get(api_url("account/verify_credentials.json"))
      return JSON.parse(response.body)
    rescue Exception => err
      logger.error("Request failed: #{err.message}")
      return {}
    end
  end
  
  # Get user name
  def get_user_name(info_hash)
    info_hash["name"]
  end
  
  # Get user screen name
  def get_user_screen_name(info_hash)
    info_hash["screen_name"]
  end
  
  # Get user id
  def get_user_id(info_hash)
    info_hash["id_str"]
  end
  
  # Get user friends count
  def get_user_friends_count(info_hash)
    info_hash["friends_count"]
  end
  
  # Follow a user
  def follow_user(atoken, screen_name, follow)
    atoken.post(api_url("friendships/create.json"), {:screen_name => screen_name, :follow => follow})
  end
  
  # Unfollow a user
  def unfollow_user(atoken, screen_name)
    atoken.post(api_url("friendships/destroy.json"), {:screen_name => screen_name})
  end
  
  # Search for users
  def user_search(atoken, query)
    begin
      response = atoken.get(api_url("users/search.json?q=#{query}"))
      return JSON.parse(response.body)
    rescue Exception => err
      logger.error("Request failed: #{err.message}")
      return []
    end
  end
                           
end