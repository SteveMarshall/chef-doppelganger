#!/usr/bin/env ruby
# encoding: UTF-8

require 'json'
require 'sinatra'

set :cookbook_store, Dir.pwd

get '/cookbooks' do
  cookbooks = Hash.new
  Dir.glob("#{settings.cookbook_store}/*.git") do |path|
    name = File.basename(path, ".git")
    cookbooks[name] = render_cookbook(path)
  end

  content_type :json
  cookbooks.to_json
end

get '/cookbooks/:name' do
  path = "#{settings.cookbook_store}/#{params[:name]}.git"
  pass unless Dir.exists?(path)

  content_type :json
  {
    params[:name] => render_cookbook(path)
  }.to_json
end

def render_cookbook(path)
  name = File.basename(path, ".git")
  repo = Git.bare(path)

  versions = repo.tags.map do |tag|
    tag_to_chef_version(name, tag)
  end

  {
    url: "/cookbooks/#{name}",
    versions: versions,
  }
end

def tag_to_chef_version(cookbook_name, version_tag)
  version_name = version_tag.name.gsub(/^v/, '')
  {
    url: "/cookbooks/#{cookbook_name}/#{version_name}",
    version: version_name,
  }
end
