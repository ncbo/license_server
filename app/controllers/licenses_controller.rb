require 'openssl'
require 'base64'
require 'uuid'

class LicensesController < ApplicationController
  layout 'main'

  before_action :check_for_cancel, :only => [:create, :update]


  def index
    if session[:user].nil?
      redirect_to :controller => 'login', :action => 'index'
    else
      @licenses = License.order(:valid_date).where(bp_username: session[:user].username)
      render action: "index"
    end
  end

  def new
    if session[:user].nil?
      redirect_to :controller => 'login', :action => 'index'
    else
      @license = License.new
    end
  end


  def show


  end

  def create
    params[:license].permit!
    @license = License.new(params[:license])
    validate

    if @errors
      render action: "new"
    end
  end

  def update

  end

  private

  def check_for_cancel
    if params[:cancel] == "Cancel"
      redirect_to licenses_path
    end
  end

  def validate
    uid_valid = UUID.validate(params["license"]["appliance_id"])

    unless uid_valid
      error = OpenStruct.new appliance_id_invalid: "#{params["license"]["appliance_id"]} is not a valid Appliance ID"
      @errors = Hash[:error, OpenStruct.new(acronym: error)]
    end
  end

end
