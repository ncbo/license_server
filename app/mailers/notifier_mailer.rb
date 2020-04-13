class NotifierMailer < ApplicationMailer
  def license_request_submitted
    @license = params[:license]
    mail(to: params[:user].email, subject: "License Request Received - Appliance ID: #{@license.appliance_id}")
  end

  def license_request_submitted_admin
    @license = params[:license]
    mail(to: $ADMIN_EMAIL, subject: "License Request Submitted - ID: #{@license.id}, Appliance ID: #{@license.appliance_id}")
  end

  def license_request_approved
    @license = params[:license]
    mail(to: params[:user].email, subject: "License Request Approved - Appliance ID: #{@license.appliance_id}")
  end

  def license_request_disapproved
    @license = params[:license]
    mail(to: params[:user].email, subject: "License Request Needs Additional Info - Appliance ID: #{@license.appliance_id}")
  end

  def license_to_expire
    @license = params[:license]
    mail(to: params[:user].email, subject: "License Expires Soon - Appliance ID: #{@license.appliance_id}")
  end
end
