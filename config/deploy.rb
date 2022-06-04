set :application, "B1Tech"
set :repo_url, "git@github.com:B1-Tech/B1-Tech_Website.git"

# Deploy to the user's home directory
set :deploy_to, "/home/alpha/#{fetch :application}"

append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', '.bundle', 'public/system', 'public/uploads'

# Only keep the last 5 releases to save disk space
set :keep_releases, 5

set :passenger_restart_with_touch, true

# Optionally, you can symlink your database.yml and/or secrets.yml file from the shared directory during deploy
# This is useful if you don't want to use ENV variables
# append :linked_files, 'config/database.yml', 'config/secrets.yml'
