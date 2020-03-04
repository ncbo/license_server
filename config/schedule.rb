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

minutes = CronParser::Cron.minutes_from_string(Rails.configuration.cron_seed).to_s
cron_parser = CronParser::Cron.parse($LICENSE_TO_EXPIRE_NOTIFICATION_CRON)
cron_parser.minutes = [minutes] if minutes && !minutes.empty?
cron_exp = cron_parser.to_cron_s

every "#{cron_exp}" do
  rake 'batch:send_licence_to_expire_notifications'
end