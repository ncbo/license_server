# Preview all emails at http://localhost:3000/rails/mailers/notifier_mailer
class NotifierMailerPreview < ActionMailer::Preview
  include ApplicationHelper

  def license_request_submitted
    lic = License.first
    user = find_user_by_bp_username(lic.bp_username)
    NotifierMailer.with(user: user, license: lic).license_request_submitted
  end

  def license_request_submitted_admin
    lic = License.first
    user = find_user_by_bp_username(lic.bp_username)
    NotifierMailer.with(user: user, license: lic).license_request_submitted_admin
  end

  def license_request_approved
    lic = License.where.not(license_key: [nil, ""]).where.not(valid_date: nil).first
    user = find_user_by_bp_username(lic.bp_username)
    NotifierMailer.with(user: user, license: lic).license_request_approved
  end
end
