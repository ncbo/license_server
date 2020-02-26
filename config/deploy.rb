# config valid for current version and patch releases of Capistrano
lock "~> 3.12.0"

set :application, "license_server"
set :repo_url, "git@github.com:ncbo/license_server.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/srv/rails/#{fetch(:application)}"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml"

# Default value for linked_dirs is []
set :linked_dirs, %w{bin log tmp/pids tmp/cache public/system public/assets}
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

set :bundle_flags, '--without development test --deployment'

#If you want to restart using `passenger-config restart-app`, add this to your config/deploy.rb:
#set :passenger_restart_with_touch, false # Note that `nil` is NOT the same as `false` here
#If you don't set `:passenger_restart_with_touch`, capistrano-passenger will check what version of passenger you are running
#and use `passenger-config restart-app` if it is available in that version.
set :passenger_restart_with_touch, true

namespace :deploy do

  desc 'display remote system env vars' 
  task :show_remote_env do
    on roles(:all) do
      remote_env = capture("env")
      puts remote_env
    end
  end

  desc 'Incorporate the bioportal_conf private repository content'
  #Get cofiguration from repo if PRIVATE_CONFIG_REPO env var is set 
  #or get config from local directory if LOCAL_CONFIG_PATH env var is set 
  task :get_config do
     if defined?(PRIVATE_CONFIG_REPO)
       TMP_CONFIG_PATH = "/tmp/#{SecureRandom.hex(15)}"
       on roles(:web) do
          execute "git clone -q #{PRIVATE_CONFIG_REPO} #{TMP_CONFIG_PATH}"
          execute "rsync -av #{TMP_CONFIG_PATH}/#{fetch(:application)}/ #{release_path}/"
          execute "rm -rf #{TMP_CONFIG_PATH}"
       end
     elsif defined?(LOCAL_CONFIG_PATH) 
       on roles(:web) do
          execute "rsync -av #{LOCAL_CONFIG_PATH}/#{fetch(:application)}/ #{release_path}/"
       end
     end
  end

  after :updating, :get_config

  end

