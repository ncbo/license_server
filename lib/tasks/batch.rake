require "#{Rails.root}/app/helpers/application_helper"
require 'csv'
require 'activerecord-import'

namespace :batch do
  desc "Rake job for batch operations"

  task send_licence_to_expire_notifications: :environment do
    today = Date.today.strftime('%Y-%m-%d')
    cutoff_date = (Date.today + $LICENCE_TO_EXPIRE_NUM_DAYS_ADVANCE).strftime('%Y-%m-%d')
    licenses = License.latest_licenses(License.approval_statuses[:approved], "expiration_reminder_sent = false", "valid_date >= '#{today}'", "valid_date <= '#{cutoff_date}'")

    licenses.each do |license|
      mail_user = find_user_by_bp_username(license.bp_username)
      NotifierMailer.with(user: mail_user, license: license).license_to_expire.deliver_now if mail_user
      license.expiration_reminder_sent = true
      license.save
    end
  end

  task import_initial_data: :environment do
    items = []
    CSV.open('data/ncbo_virtual_appliance_data.csv', 'r:bom|utf-8', headers: true) { |csv| csv.each { |row| items << row.to_h } }
    License.import(items)
  end
end
