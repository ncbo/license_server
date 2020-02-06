require 'openssl'
require 'base64'
require 'uuid'

class LicensesController < ApplicationController
  skip_before_action :verify_authenticity_token
  layout 'main'
  before_action :check_for_cancel, :only => [:create, :update]
  before_action :init_license_purposes

  def index
    if session[:user].nil?
      redirect_to :controller => 'login', :action => 'index'
    else
      render_licenses
      render action: :index
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

  def approve
    license = License.find(params[:id])
    license.approval_status = License.approval_statuses[:approved]

    # generate valid date and license key only the first time
    if license.valid_date.nil? || license.license_key.nil?
      valid_date = Date.today + $LICENSE_VALIDITY_MONTHS.months
      license.valid_date = valid_date
      private_key = File.read($PRIVATE_KEY_FILE)
      raw_data = "#{license.appliance_id};#{license.organization};#{valid_date}"
      lic_key = EncryptionUtil.encrypt(private_key, raw_data)
      license.license_key = lic_key
    end

    license.save
    flash[:success] = "License with ID: #{license.id} has been approved."
    redirect_to licenses_path
  end

  def disapprove
    license = License.find(params[:id])
    license.approval_status = License.approval_statuses[:disapproved]
    license.valid_date = nil
    license.license_key = nil
    license.save
    flash[:success] = "License with ID: #{license.id} has been disapproved."
    redirect_to licenses_path
  end

  def renew
    license = License.find(params[:id])
    license.id = nil
    @license = license
    render action: :new
  end

  def edit
    @license = License.find(params[:id])
    render action: :edit
  end

  def create
    save_license_from_params(:new)

    if @license.approval_status === License.approval_statuses[:approved]
      params[:id] = @license.id
      approve
    end
  end

  def update
    save_license_from_params(:edit)
  end

  def destroy
    license = License.find(params[:id])
    license.destroy!
    flash[:success] = "License with ID: #{params[:id]} has been deleted."
    redirect_to licenses_path
  end

  private

  def render_licenses
    lic_arr = nil
    lic_hash = {}

    if helpers.current_user_admin?
      lic_arr = License.order('approval_status DESC, valid_date')
    else
      lic_arr = License.order('approval_status DESC, valid_date').where(bp_username: session[:user].username)
    end

    lic_arr.each do |lic|
      if lic_hash[lic.appliance_id]
        lic_hash[lic.appliance_id] << lic
      else
        lic_hash[lic.appliance_id] = [lic]
      end
    end

    @licenses = lic_hash.values.flatten
  end

  def save_license_from_params(action)
    params[:license].permit!

    if params[:id]
      @license = License.find(params[:id])
    else
      @license = License.new
    end

    @license.bp_username = session[:user].username
    @license.assign_attributes(params[:license])
    validate

    if @errors
      render action: action
    else
      if @license.valid?
        @license.save

        if action === :new
          flash[:success] = "New license with ID: #{@license.id} has been successfully created."
        else
          flash[:success] = "License with ID: #{@license.id} has been successfully updated."
        end
        redirect_to licenses_path
      else
        @errors = response_errors(@license.errors)
        render action: action
      end
    end
  end

  def check_for_cancel
    if params[:cancel] == "Cancel"
      redirect_to licenses_path
    end
  end

  def init_license_purposes
    @license_purposes = LicensePurpose.all.order(:sort_order)
  end

  def validate
    re = Regexp.new("^#{$LEGACY_APPLIANCE_ID}-[0-9a-z]+$").freeze
    uid_valid = re.match?(params[:license][:appliance_id]) || UUID.validate(params[:license][:appliance_id])

    unless uid_valid
      error = OpenStruct.new appliance_id_invalid: "#{params[:license][:appliance_id]} is not a valid Appliance ID"
      @errors = Hash[:error, OpenStruct.new(appliance_id: error)]
    end
  end

end
