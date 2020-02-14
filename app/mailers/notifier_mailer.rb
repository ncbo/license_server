class NotifierMailer < ApplicationMailer


  def license_request_submitted
    @license = params[:license]
    mail(to: params[:user].email, subject: "License Key Request for Appliance ID: #{@license.appliance_id} Received")
  end


end
