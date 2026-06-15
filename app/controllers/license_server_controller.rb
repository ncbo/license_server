class LicenseServerController < ApplicationController
  layout 'main'

  def index
    if helpers.logged_in?
      redirect_to licenses_path
    else
      render action: :index
    end
  end
end
