# coding: utf-8
require "bundler/capistrano"
require "sidekiq/capistrano"

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

set :application, "community"
set :repository,  "git@github.com:poiyzy/ruby-china.git"
set :branch, "zirannanren"
set :scm, :git
set :user, "poiyzy"
if ENV["DEPLOY"] == "pre"
  set :deploy_to, "/home/#{user}/apps/#{application}-pre"
else
  set :deploy_to, "/home/#{user}/apps/#{application}"
end
set :deploy_via, :remote_cache
# set :runner, "poiyzy"
set :use_sudo, false
# set :git_shallow_clone, 1

role :web, "42.121.111.183"                          # Your HTTP server, Apache/etc
role :app, "42.121.111.183"                          # This may be the same as your `Web` server
role :db,  "42.121.111.183", :primary => true # This is where Rails migrations will run

# unicorn.rb 路径
set :unicorn_path, "#{deploy_to}/current/config/unicorn.rb"

namespace :deploy do
  task :start, :roles => :app do
    run "cd #{deploy_to}/current/; RAILS_ENV=production bundle exec unicorn_rails -c #{unicorn_path} -D"
  end

  task :stop, :roles => :app do
    run "kill -QUIT `cat #{deploy_to}/current/tmp/pids/unicorn.pid`"
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "kill -USR2 `cat #{deploy_to}/current/tmp/pids/unicorn.pid`"
  end
end

namespace :faye do
  desc "Start Faye"
  task :start, :roles => :app do
    run "cd #{deploy_to}/current/faye_server; thin start -C thin.yml"
  end

  desc "Stop Faye"
  task :stop, :roles => :app do
    run "cd #{deploy_to}/current/faye_server; thin stop -C thin.yml"
  end

  desc "Restart Faye"
  task :restart, :roles => :app do
    run "cd #{deploy_to}/current/faye_server; thin restart -C  thin.yml"
  end
end


task :init_shared_path, :roles => :app do
  run "mkdir -p #{deploy_to}/shared/log"
  run "mkdir -p #{deploy_to}/shared/pids"
  run "mkdir -p #{deploy_to}/shared/assets"
end

task :link_shared_files, :roles => :app do
  run "ln -sf #{deploy_to}/shared/config/*.yml #{deploy_to}/current/config/"
  run "ln -sf #{deploy_to}/shared/config/unicorn.rb #{deploy_to}/current/config/"
  run "ln -sf #{deploy_to}/shared/config/initializers/secret_token.rb #{deploy_to}/current/config/initializers"
  run "ln -sf #{deploy_to}/shared/config/faye_thin.yml #{deploy_to}/current/faye_server/thin.yml"
  sudo "ln -nfs #{deploy_to}/current/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
end

task :mongoid_create_indexes, :roles => :app do
  run "cd #{deploy_to}/current/; RAILS_ENV=production bundle exec rake db:mongoid:create_indexes"
end

task :compile_assets, :roles => :app do
  run "cd #{deploy_to}/current/; RAILS_ENV=production bundle exec rake assets:precompile"
end

task :sync_assets_to_cdn, :roles => :web do
  run "cd #{deploy_to}/current/; RAILS_ENV=production bundle exec rake assets:cdn"
end

task :mongoid_migrate_database, :roles => :app do
  run "cd #{deploy_to}/current/; RAILS_ENV=production bundle exec rake db:migrate"
end

after "deploy:finalize_update","deploy:symlink", :init_shared_path, :link_shared_files, :compile_assets, :sync_assets_to_cdn, :mongoid_migrate_database
# after "deploy:finalize_update","deploy:symlink", :init_shared_path, :link_shared_files, :compile_assets, :mongoid_migrate_database
