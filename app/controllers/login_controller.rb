class LoginController < ApplicationController
  skip_before_action :verify_authenticity_token
  layout 'main'

  def index
    if helpers.logged_in?
      redirect_to licenses_path
    end

    # Sets the redirect properties
    if params[:redirect]
      # Get the original, encoded redirect
      uri = URI.parse(request.url)
      orig_params = Hash[uri.query.split("&").map {|e| e.split("=",2)}].symbolize_keys
      session[:redirect] = orig_params[:redirect]
    else
      session[:redirect] = request.referer
    end
  end

  # logs in a user
  def create
    @errors = validate(params[:user])

    unless @errors[:error]
      logged_in_user = LinkedData::Client::Models::User.authenticate(params[:user][:username], params[:user][:password])

      if logged_in_user && !logged_in_user.errors
        login(logged_in_user)
        redirect = licenses_path

        if session[:redirect]
          redirect = CGI.unescape(session[:redirect])
        end

        redirect_to redirect
      else
        error = OpenStruct.new login_invalid: "Invalid username/password combination"
        @errors = Hash[:error, OpenStruct.new(user_username: error)]
        render action: 'index'
      end
    else
      render action: 'index'
    end
  end

  # Login as the provided username (only for admin users)
  def login_as
    unless helpers.current_user_admin?
      redirect_to "/"
      return
    end

    bp_username = params[:login_as]
    new_user = helpers.find_user_by_bp_username(bp_username)

    if new_user
      session[:admin_user] = session[:user]
      session[:user] = new_user
      session[:user].apikey = session[:admin_user].apikey
    end

    redirect_to request.referer rescue redirect_to "/"
  end

  # logs out a user
  def destroy
    session[:user] = nil
    flash[:notice] = "Logged out"
    redirect_to root_path
  end

  private

  def login(user)
    return unless user
    session[:user] = user
    session[:user][:admin] = user.admin?
  end

  def validate(params)
    errors = {}
    err_hash = OpenStruct.new

    if params[:username].nil? || params[:username].length < 1
      error = OpenStruct.new username_invalid: "Please enter a valid username"
      err_hash[:user_username] = error
    end

    if params[:password].nil? || params[:password].length < 1
      error = OpenStruct.new password_invalid: "Please enter a password"
      err_hash[:user_password] = error
    end

    errors[:error] = err_hash unless err_hash.to_h.empty?
    errors
  end
end
