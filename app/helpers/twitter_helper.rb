module TwitterHelper
  # Check if the user is signed in
  def signed_in?
    if session[:atoken]
      return true
    else
      return false
    end
  end
end
