require 'openssl'
require 'base64'
require 'uuid'

class LicensesController < ApplicationController
  skip_before_action :verify_authenticity_token
  layout 'main'
  before_action :check_access
  before_action :check_for_cancel, :only => [:create, :update]
  before_action :init_license_purposes

  def index
    render_licenses
    render action: :index
  end

  def new
    @license = License.new

    unless helpers.current_user_admin?
      unless session[:user].firstName.strip.empty?
        @license.first_name = session[:user].firstName.strip
      end
      unless session[:user].lastName.strip.empty?
        @license.last_name = session[:user].lastName.strip
      end
    end
  end

  def edit
    @license = License.find(params[:id])
    # for non-admins allow editing only in "pending" state
    if helpers.current_user_admin? || @license.approval_status === License.approval_statuses[:pending]
      render action: :edit
    else
      render action: :show
    end
  end

  def show
    @license = License.find(params[:id])
    render action: :show
  end

  def approve
    approve_license(params[:id])
    flash[:success] = "License with ID: #{params[:id]} has been approved."
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

  def create
    save_license_from_params

    if @errors[:error]
      render action: :new
    else
      success = "New #{license_id_msg(@license.id)} has been successfully created."
      mail_user = helpers.current_user_admin? ? helpers.find_user_by_bp_username(@license.bp_username) : session[:user]
      # notify user of application received
      NotifierMailer.with(user: mail_user, license: @license).license_request_submitted.deliver_now

      if @license.approval_status === License.approval_statuses[:approved]
        params[:id] = @license.id
        approve_license(@license.id)
        success << " A license key has been generated."
      end

      flash[:success] = success
      redirect_to licenses_path
    end
  end

  def update
    save_license_from_params

    if @errors[:error]
      render action: :edit
    else
      flash[:success] = "#{license_id_msg(@license.id)} has been successfully updated."
      redirect_to licenses_path
    end
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
    max_id_sql = nil

    if helpers.current_user_admin?
      max_id_sql = "SELECT appliance_id, MAX(id) FROM licenses GROUP BY appliance_id"
      lic_arr = License.order('approval_status DESC, valid_date')
    else
      max_id_sql = "SELECT appliance_id, MAX(id) FROM licenses WHERE bp_username = '#{session[:user].username}' GROUP BY appliance_id"
      lic_arr = License.order('approval_status DESC, valid_date DESC').where(bp_username: session[:user].username)
    end

    max_ids_raw = License.connection.select_all(max_id_sql)
    max_ids = max_ids_raw.rows.to_h

    lic_arr.each do |lic|
      if lic.id === max_ids[lic.appliance_id]
        lic.latest = true
      else
        lic.latest = false
      end

      if lic_hash[lic.appliance_id]
        lic_hash[lic.appliance_id] << lic
      else
        lic_hash[lic.appliance_id] = [lic]
      end
    end

    @licenses = lic_hash.values.flatten
  end

  def approve_license(id)
    license = License.find(id)
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
  end

  def save_license_from_params()
    params[:license].permit!

    if params[:id]
      @license = License.find(params[:id])
    else
      @license = License.new
    end

    params[:license][:bp_username] ||= session[:user].username
    @license.assign_attributes(params[:license])
    @errors = validate(params[:license])

    unless @errors[:error]
      if @license.valid?
        @license.save
      else
        @errors = response_errors(@license.errors)
      end
    end
  end

  def check_access()
    redirect_to controller: 'login', action: 'index' unless helpers.logged_in?

    if !helpers.current_user_admin? && params[:id]
      license = License.find_by(id: params[:id])
      render file: 'public/403.html', status: :forbidden if license.nil? || license.bp_username != session[:user].username
    end
  end

  def check_for_cancel()
    if params[:cancel] == "Cancel"
      redirect_to licenses_path
    end
  end

  def init_license_purposes()
    @license_purposes = LicensePurpose.all.order(:sort_order)
  end

  def validate(params)
    errors = {}
    err_hash = OpenStruct.new
    re = Regexp.new("^#{$LEGACY_APPLIANCE_ID}-[0-9a-z]+$").freeze
    uid_valid = re.match?(params[:appliance_id]) || UUID.validate(params[:appliance_id])

    unless uid_valid
      error = OpenStruct.new appliance_id_invalid: "#{params[:appliance_id]} is not a valid Appliance ID"
      err_hash[:license_appliance_id] = error
    end

    bp_user = helpers.find_user_by_bp_username(params[:bp_username])

    unless bp_user
      error = OpenStruct.new username_invalid: "#{params[:bp_username]} is not a valid BioPortal user"
      err_hash[:license_bp_username] = error
    end

    errors[:error] = err_hash unless err_hash.to_h.empty?
    errors
  end

  def license_id_msg(id)
    msg = "License"

    if helpers.current_user_admin?
      msg << " with ID: #{id}"
    end
    msg
  end

end
