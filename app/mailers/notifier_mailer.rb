class NotifierMailer < ApplicationMailer

  def license_request_submitted
    @license = params[:license]
    mail(to: params[:user].email, subject: "License Request for Appliance ID: #{@license.appliance_id} Received")
  end

  def license_request_submitted_admin
    @license = params[:license]
    mail(to: params[:user].email, subject: "License Request (ID: #{@license.id}) for Appliance ID: #{@license.appliance_id} Submitted")
  end

end
