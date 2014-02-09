require './lib/cookbook_server'
set :environment, :production
set :cookbook_store, "./cookbooks"
run Sinatra::Application
