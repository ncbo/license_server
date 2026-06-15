source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# === Framework (path-C modernization: Rails 5.1.7 -> 8.0.3, Ruby 2.7.8 -> 3.2.9) ===
gem 'rails', '8.0.3'
gem 'puma', '~> 6.0'                 # was ~> 3.7; run puma directly (drop Passenger)
gem 'bootsnap', require: false       # Rails 8 boot cache
gem 'tzinfo-data', platforms: %i[windows jruby]

# Rails 8.0.x compatibility pins (mirrors bioportal_web_ui)
gem 'concurrent-ruby', '= 1.3.4'     # ActiveSupport logger bug on 8.0.x
gem 'connection_pool', '< 3'         # connection_pool 3 breaks MemCacheStore on 8.0.x

# === Database / cache ===
gem 'mysql2'                         # was '>= 0.3.18', '< 0.6.0'
gem 'dalli'                          # memcached (:mem_cache_store)

# === Asset pipeline (kept on Sprockets per decision) ===
gem 'sprockets-rails'
gem 'sassc-rails'                    # SCSS for Sprockets (replaces sass-rails ~> 5.0)
gem 'terser'                         # replaces uglifier
gem 'bootstrap', '~> 4.6'            # was ~> 4.1.0 (keep Bootstrap 4 look)
gem 'jquery-rails'
gem 'jquery-ui-rails'

# === Views / domain helpers ===
gem 'haml', '~> 6.1'                 # was unversioned (5.x)
gem 'chroma'                         # per-appliance license row colors
gem 'uuid'                           # appliance-id validation
gem 'fugit'                          # cron parsing (schedule.rb / cron_parser)
gem 'ruby-xxHash'                    # deterministic per-host cron minute jitter
gem 'rest-client'
gem 'multi_json'
gem 'oj'                             # fast JSON (client uses it)
gem 'activerecord-import', require: false  # batch:import_initial_data

# Ruby 3.x stdlib gems now bundled explicitly (mirrors web_ui)
gem 'ffi'
gem 'net-http'
gem 'net-ftp', require: false

# === BioPortal API client (modern tag; brings faraday 2.x — replaces the v2.0.0
# pin + the faraday ~> 1.10 stopgap). Spike-verified against the live API. ===
gem 'ontologies_api_client', github: 'ncbo/ontologies_api_ruby_client', tag: 'v2.9.0'

gem 'pry'

gem 'whenever', group: :deployment, require: false

# deployment group for capistrano deployments
group :deployment, :development do
  gem 'bcrypt_pbkdf', '>= 1.0', '< 2.0', require: false # https://github.com/miloserdow/capistrano-deploy/issues/42
  gem 'capistrano', '~> 3.17', require: false
  gem 'capistrano-rbenv', require: false
  gem 'capistrano-passenger', require: false
  gem 'capistrano-rails', '~> 1.4', require: false
  gem 'capistrano-rails-db', require: false
  gem 'ed25519', '>= 1.2', '< 2.0', require: false # https://github.com/miloserdow/capistrano-deploy/issues/42
end

group :development, :test do
  gem 'debug', platforms: %i[mri windows]  # replaces byebug
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
end

group :development do
  gem 'listen'
  gem 'web-console'
  gem 'brakeman', require: false
  gem 'rubocop', require: false
end

# Rails 8's test runner is incompatible with minitest 6.x; pin to 5.x
# (same fix bioportal_web_ui uses).
gem 'minitest', '~> 5.25'

group :test do
  gem 'webmock'  # available to stub the two BioPortal API calls if needed
end
