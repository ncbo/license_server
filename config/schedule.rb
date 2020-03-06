# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
require_relative 'environment'

log_path = Rails.root.join('log', "crontab_#{Rails.env}.log")
set :output, "#{log_path}"
logger = ActiveSupport::Logger.new(log_path)
logger.datetime_format = "%Y-%m-%d %H:%M:%S"

env :PATH, ENV['PATH']

cron_seed = SecureRandom.uuid
minutes = CronParser::Cron.minutes_from_string(cron_seed).to_s
cron_parser = CronParser::Cron.parse($LICENSE_TO_EXPIRE_NOTIFICATION_CRON)
cron_parser.minutes = [minutes] if minutes && !minutes.empty?
cron_exp = cron_parser.to_cron_s

job1 = 'batch:send_licence_to_expire_notifications'
logger.info "Generated a CRON job for '#{job1}' with schedule: '#{cron_exp}'"

every "#{cron_exp}" do
  rake job1
end