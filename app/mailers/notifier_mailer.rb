class NotifierMailer < ApplicationMailer

  def license_request_submitted
    @license = params[:license]
    mail(to: params[:user].email, subject: "License Request for Appliance ID: #{@license.appliance_id} Received")
  end

  def license_request_submitted_admin
    @license = params[:license]
    mail(to: $ADMIN_EMAIL, subject: "License Request (ID: #{@license.id}) for Appliance ID: #{@license.appliance_id} Submitted")
  end

  def license_request_approved
    @license = params[:license]
    mail(to: params[:user].email, subject: "License Request for Appliance ID: #{@license.appliance_id} Approved")
  end

  def license_request_disapproved
    @license = params[:license]
    mail(to: params[:user].email, subject: "License Request for Appliance ID: #{@license.appliance_id} Needs Additional Info")
  end

  def license_to_expire
    @license = params[:license]
    mail(to: params[:user].email, subject: "License for Appliance ID: #{@license.appliance_id} Expires Soon")
  end

end
