require "#{Rails.root}/app/helpers/application_helper"
include ApplicationHelper

namespace :batch do
  desc "Send out batch email notifications"

  task send_licence_to_expire_notifications: :environment do
    today = Date.today.strftime('%Y-%m-%d')
    cutoff_date = (Date.today + $LICENCE_TO_EXPIRE_NUM_DAYS_ADVANCE).strftime('%Y-%m-%d')
    licenses = License.latest_licenses(License.approval_statuses[:approved], "valid_date >= '#{today}'", "valid_date <= '#{cutoff_date}'")

    licenses.each do |license|
      mail_user = find_user_by_bp_username(license.bp_username)
      NotifierMailer.with(user: mail_user, license: license).license_to_expire.deliver_now if mail_user
    end
  end

end
