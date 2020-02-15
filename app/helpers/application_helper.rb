module ApplicationHelper
  def current_user_admin?
    session[:user] && session[:user].admin?
  end

  def logged_in?
    !session[:user].nil?
  end

  def find_user_by_bp_username(bp_username)
    LinkedData::Client::Models::User.find_by_username(bp_username).first
  end

  def license_expired?(license)
    license.valid_date && license.valid_date.to_date < Date.today
  end
end
