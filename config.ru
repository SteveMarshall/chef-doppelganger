require File.expand_path '../cookbook_server.rb', __FILE__
set :environment, :production
set :cookbook_store, "./cookbooks"
run Sinatra::Application
