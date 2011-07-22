class ApplicationController < ActionController::Base
  require 'twitter_wrapper.rb'
  protect_from_forgery
end
