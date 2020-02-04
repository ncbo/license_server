class LoginController < ApplicationController
  skip_before_action :verify_authenticity_token
  layout 'main'

  def index
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
    if @errors.size < 1
      logged_in_user = LinkedData::Client::Models::User.authenticate(params[:user][:username], params[:user][:password])

      if logged_in_user && !logged_in_user.errors
        login(logged_in_user)
        redirect = licenses_path

        if session[:redirect]
          redirect = CGI.unescape(session[:redirect])
        end

        redirect_to redirect
      else
        @errors << "Invalid account name/password combination"
        render :action => 'index'
      end
    else
      render :action => 'index'
    end
  end

  # Login as the provided username (only for admin users)
  def login_as
    unless session[:user] && session[:user].admin?
      redirect_to "/"
      return
    end

    user = params[:login_as]
    new_user = LinkedData::Client::Models::User.find_by_username(user).first

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
    redirect_to request.referer || "/"
  end

  private

  def login(user)
    return unless user
    session[:user] = user
    session[:user][:admin] = user.admin?
  end

  def validate(params)
    errors=[]

    if params[:username].nil? || params[:username].length <1
      errors << "Please enter an account name"
    end
    if params[:password].nil? || params[:password].length <1
      errors << "Please enter a password"
    end

    return errors
  end


end
