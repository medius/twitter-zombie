class TwitterController < ApplicationController
  require 'twitter_wrapper.rb'
  before_filter :twitter_wrapper  
    
  def index
    begin      
      puts "Index enter"
      @twitter = @wrapper.get_twitter(session[:atoken], session[:asecret])
      puts "Got Twitter"
      @account = @twitter.user_timeline.first.user.screen_name
      @tweets = @twitter.home_timeline
    rescue
      puts "No twitter"
      @twitter = nil
    end
  end
  
  def signin
    begin
      puts "Signin"
      session[:rtoken], session[:rsecret] = @wrapper.request_tokens
      puts "Requested token"
      redirect_to @wrapper.authorize_url
    rescue
      puts "Signin rescue"
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
  
  def tweet
    begin
      @twitter = @wrapper.get_twitter
      @twitter.update params[:tweet]
      flash[:notice] = "Tweet successfully sent!"
    rescue
      flash[:error] = "Error sending the tweet! Twitter might be unstable. Please try again."
    end
    redirect_to :action => :index
  end
  
  private
  
  def twitter_wrapper
    @wrapper = TwitterWrapper.new File.join(Rails.root, 'config', 'twitter.yml')
    puts "twitter wrapper: #{@wrapper}"
  end
   
end