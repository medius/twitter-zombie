class TwitterController < ApplicationController
  require 'twitter_wrapper.rb'
  before_filter :twitter_wrapper  
  
  respond_to :html, :json, :js
      
  def index
    begin      
      @twitter = @wrapper.get_twitter(session[:atoken], session[:asecret])
      begin
        @account = @twitter.user_timeline.first.user.screen_name
      rescue
        @account = ""
      end
      
      begin
        @tweets = @twitter.home_timeline
      rescue
        @tweets = [];
      end
      
      begin
        @friends = @twitter.friends.paginate(:per_page => 20, :page => params[:page])
      rescue
        @friends = []
      end
      
      begin
        @name = @twitter.user(@account)[:name]
      rescue
        @name = ""
      end
      
    rescue
      #puts "SOmething went wrong"
      @twitter = nil
    end
    
  end
  
  def signin
    begin
      session[:rtoken], session[:rsecret] = @wrapper.request_tokens
      redirect_to @wrapper.authorize_url
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
      session[:atoken], session[:asecret] = @wrapper.auth(session[:rtoken], session[:rsecret], params[:oauth_verifier])
      flash[:notice] = "Successfully signed in with Twitter."
    rescue
      flash[:error] = 'You were not authorized by Twitter!'
    end
    redirect_to :action => :index
  end
  
  
  def unfollow
    begin
      @twitter = @wrapper.get_twitter(session[:atoken], session[:asecret])
      params[:friend_ids].each do |friend_id|
        begin
          @data = @twitter.friendship_destroy(friend_id)
        rescue
          flash[:error] = "Error in unfollowing #{friend_id}"
        end
      end
    rescue
      flash[:error] = "Error sending the unfollowing! Please try again."
    end
    redirect_to root_url, :notice => "Unfollow complete."
  end
  
  def search
    begin
      @twitter = @wrapper.get_twitter(session[:atoken], session[:asecret])
      @results = @twitter.user_search(params[:search])
      respond_with(@results)
    rescue
      flash[:error] = "Error in searching Twitter"
    end
  end
  
  def follow
    begin
      @twitter = @wrapper.get_twitter(session[:atoken], session[:asecret])
      params[:result_ids].each do |result_id|
        begin
          @data = @twitter.friendship_create(result_id, true)
        rescue
          flash[:error] = "Error in following #{result_id}"
        end
      end
    rescue
      flash[:error] = "Error in following these users! Please try again."
    end
    redirect_to root_url, :notice => "Follow complete."
  end
  
  private
  
  def twitter_wrapper
    @wrapper = TwitterWrapper.new File.join(Rails.root, 'config', 'twitter.yml')
  end
  

end