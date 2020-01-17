class LicenseServerController < ApplicationController
  skip_before_action :verify_authenticity_token
  layout 'main'

  def index
    render action: "index"
  end
end
