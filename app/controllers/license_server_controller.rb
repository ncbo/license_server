class LicenseServerController < ApplicationController
  skip_before_action :verify_authenticity_token
  layout 'main'

  def index
    if helpers.logged_in?
      redirect_to licenses_path
    else
      render action: :index
    end
  end
end
