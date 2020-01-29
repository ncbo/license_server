require 'openssl'
require 'base64'
require 'uuid'

class LicensesController < ApplicationController
  layout 'main'
  before_action :check_for_cancel, :only => [:create, :update]
  before_action :init_license_purposes

  def index



private_key = File.read($PRIVATE_KEY_FILE)
public_key  = File.read($PUBLIC_KEY_FILE)

d = Date.today >> 12

string = "#{SecureRandom.uuid};#{d}"
encrypted_string = EncryptionUtil.encrypt(private_key, string)
puts "************"
puts encrypted_string
puts "************"
puts


decrypted_string = EncryptionUtil.decrypt(public_key, encrypted_string)
puts "************"
puts decrypted_string
puts "************"





    if session[:user].nil?
      redirect_to :controller => 'login', :action => 'index'
    else
      if helpers.current_user_admin?
        @licenses = License.order('approval_status DESC, valid_date')
      else
        @licenses = License.order('approval_status DESC, valid_date').where(bp_username: session[:user].username)
      end
      render action: "index"
    end
  end

  def new
    if session[:user].nil?
      redirect_to :controller => 'login', :action => 'index'
    else
      @license = License.new
      unless session[:user].firstName.strip.empty?
        @license.first_name = session[:user].firstName.strip
      end
      unless session[:user].lastName.strip.empty?
        @license.last_name = session[:user].lastName.strip
      end
    end
  end


  def show


  end

  def edit
    @license = License.find(params[:id])
  end

  def create
    params[:license].permit!
    @license = License.new(params[:license])
    validate

    if @errors
      render action: "new"
    else

      if @license.valid?
        @license.bp_username = session[:user].username
        @license.valid_date = Date.today + $LICENSE_VALIDITY_MONTHS.months
        @license.save
        redirect_to licenses_path
      else
        @errors = response_errors(@license.errors)
        render action: "new"
      end

    end

  end

  def update
    binding.pry
  end

  private

  def check_for_cancel
    if params[:cancel] == "Cancel"
      redirect_to licenses_path
    end
  end

  def init_license_purposes
    @license_purposes = LicensePurpose.all.order(:sort_order)
  end

  def validate
    uid_valid = params[:license][:appliance_id] === $LEGACY_APPLIANCE_ID || UUID.validate(params[:license][:appliance_id])

    unless uid_valid
      error = OpenStruct.new appliance_id_invalid: "#{params[:license][:appliance_id]} is not a valid Appliance ID"
      @errors = Hash[:error, OpenStruct.new(acronym: error)]
    end
  end

end
