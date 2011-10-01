set :application, "framework-test.amee.com"
set :deploy_to, "/var/www/apps/framework"
# Source control setup
set :scm, :git
set :git_enable_submodules,1
set :git_shallow_clone, 1
set :repository,  "git@github.com:AMEE/data_mapping_prototype.git"
set :user, 'deploy'
set :domain, "flood.amee.com"
set :use_sudo, false

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

role :app, "framework-test.amee.com"
role :web, "framework-test.amee.com"
role :db,  "framework-test.amee.com", :primary => true

set :rails_env, "staging"
set :rake_path, "rake"


after "deploy:update_code", "database:copy_config", "amee:copy_config","gems:install"

namespace :database do
  desc "Make copy of database.yml on server"
  task :copy_config do
    run "cp #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
end

namespace :amee do
  desc "Make copy of amee.yml on server"
  task :copy_config do
    run "cp #{shared_path}/config/amee.yml #{release_path}/config/amee.yml"
  end
end

namespace :gems do
  desc "Install required gems on server"
  task :install do
    run "sudo #{rake_path} RAILS_ENV=#{rails_env} -f #{release_path}/Rakefile gems:install"
  end
end

namespace :deploy do
  # Restart passenger on deploy
  desc "Restarting mod_rails and background tasks with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end
  desc "Start the background daemons"
  task :start do

  end
  desc "Stop the background daemons"
  task :stop do

  end
end