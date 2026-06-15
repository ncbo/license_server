# Container configuration — reads everything from environment variables (so no
# secrets are baked into the image). The entrypoint copies this to
# config/license_server_config_<RAILS_ENV>.rb at startup. Using a Ruby file that
# reads ENV (rather than envsubst) avoids clobbering the `$GLOBAL` names.
$ORG_SITE            = ENV.fetch('ORG_SITE', 'OntoPortal Appliance License Server')
$LICENSE_SERVER_HOST = ENV.fetch('LICENSE_SERVER_HOST', 'localhost:3000')
$BP_UI_URL           = ENV.fetch('BP_UI_URL', 'https://bioportal.bioontology.org')
$BP_REST_URL         = ENV.fetch('BP_REST_URL', 'https://data.bioontology.org')
$API_KEY             = ENV.fetch('API_KEY', '')
$PURL_PREFIX         = ENV.fetch('PURL_PREFIX', 'http://purl.bioontology.org/ontology')

$PRIVATE_KEY_FILE = ENV.fetch('PRIVATE_KEY_FILE', Rails.root.join('config', 'keys', 'private.pem').to_s)
$PUBLIC_KEY_FILE  = ENV.fetch('PUBLIC_KEY_FILE',  Rails.root.join('config', 'keys', 'public.pem').to_s)

$LICENSE_VALIDITY_MONTHS = Integer(ENV.fetch('LICENSE_VALIDITY_MONTHS', '12'))
$LEGACY_APPLIANCE_ID     = ENV.fetch('LEGACY_APPLIANCE_ID', 'legacy-appliance-id')

$CLIENT_REQUEST_CACHING  = ENV.fetch('CLIENT_REQUEST_CACHING', 'false') == 'true'
$DEBUG_RUBY_CLIENT       = false
$DEBUG_RUBY_CLIENT_KEYS  = []

$LICENSE_TO_EXPIRE_NOTIFICATION_CRON = ENV.fetch('LICENSE_TO_EXPIRE_NOTIFICATION_CRON', '30 10 * * *')
$LICENCE_TO_EXPIRE_NUM_DAYS_ADVANCE  = Integer(ENV.fetch('LICENCE_TO_EXPIRE_NUM_DAYS_ADVANCE', '15'))

$SUPPORT_EMAIL  = ENV.fetch('SUPPORT_EMAIL', 'support@localhost')
$ADMIN_EMAIL    = ENV.fetch('ADMIN_EMAIL', 'admin@localhost')
$EMAIL_SENDER   = ENV.fetch('EMAIL_SENDER', 'noreply@localhost')
$EMAIL_OVERRIDE = ENV.fetch('EMAIL_OVERRIDE', 'developers@localhost')

ActionMailer::Base.smtp_settings = {
  address: ENV.fetch('SMTP_ADDRESS', 'localhost'),
  port:    Integer(ENV.fetch('SMTP_PORT', '25')),
  domain:  ENV.fetch('SMTP_DOMAIN', 'localhost')
}
