module ApplicationHelper
  def current_user_admin?
    session[:user] && session[:user][:admin]
  end

  def logged_in?
    !session[:user].nil?
  end

end
