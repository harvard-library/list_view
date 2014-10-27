# config valid only for Capistrano 3.1
lock '3.1.0'

require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'

set :application, 'hollis_links'
set :repo_url, 'git@github.com:harvard-library/hollis_links.git'

ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

set :deploy_via, :copy

set :scm, :git

set :format, :pretty

set :bundle_binstubs, nil

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Create these in /path/to/deploy/shared
set :linked_files, %w{config/database.yml .env}

set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/uploads}

set :keep_releases, 3

namespace :deploy do

  desc 'Run arbitrary remote rake task'
  task :rrake do
    on roles(:app) do
      within release_path do
        execute :rake, "#{ENV['T']} --rakefile=#{release_path}/Rakefile RAILS_ENV=#{Proc.new do fetch(:rails_env) end.call}"
      end
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end

before 'deploy:migrate', 'rvm:hook'
before 'deploy:rrake', 'rvm:hook'
before 'bundler:install', 'rvm:hook'
