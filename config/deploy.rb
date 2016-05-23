# config valid only for current version of Capistrano
lock '3.5.0'

set :application, 'anidb'
set :repo_url, '.'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/anidb'

# Default value for :scm is :git
set :scm, :rsync
set :rsync_options, %w[
  --recursive --delete --delete-excluded 
  --include /web/public/build/
  --exclude .git*
  --exclude /data
  --exclude /config
  --exclude /web/public/*
  --exclude .gitignore
  --exclude .rspec
]

namespace :rsync do
    # Create an empty task to hook with. Implementation will be come next
    task :stage_done

    # Then add your hook
    after :stage_done, :precompile do
      public_dir = File.expand_path(File.join(fetch(:rsync_stage), 'web/public'))
      shared_node_modules_dir = File.expand_path(File.join(fetch(:rsync_stage), '../node_modules'))
      current_node_modules_dir = File.expand_path(File.join(public_dir, 'node_modules'))
      Dir.chdir public_dir do
        File.symlink(node_modules_dir, current_node_modules_dir) unless File.symlink?(current_node_modules_dir)
        system("npm install && npm run build")
      end
    end
end

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('data', 'tmp/pids', 'tmp/sockets', 'log')

set :puma_rackup, -> { File.join(current_path, 'web', 'config.ru') }

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do

  after :check, :create_directories do
    on roles(:app) do
      http_cache_dir = File.join(shared_path, "data/http_anime_info_cache")
      udp_cache_dir = File.join(shared_path, "data/udp_anime_info_cache/lock")
      unless test(http_cache_dir)
        execute "mkdir -p #{http_cache_dir}"
      end  
      unless test(udp_cache_dir)
        execute "mkdir -p #{udp_cache_dir}"
      end  
    end
  end  

  after :restart, :clear_cache do
    on roles(:app), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end