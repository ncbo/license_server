module ApplicationHelper


  def current_user_admin?
    session[:user] && session[:user].admin?
  end


end
