#!/usr/bin/env ruby
# encoding: UTF-8

require 'json'
require 'sinatra'

set :cookbook_store, Dir.pwd

get '/cookbooks' do
  cookbooks = Hash.new
  Dir.glob("#{settings.cookbook_store}/*.git") do |cookbook_path|
    name = File.basename(cookbook_path, ".git")
    repo = Git.bare(cookbook_path)

    versions = repo.tags.reverse.map do |tag|
      tag_to_chef_version(name, tag)
    end
    cookbooks[name] = {
      url: "/cookbooks/#{name}",
      versions: versions.reverse,
    }
  end

  content_type :json
  cookbooks.to_json
end

def tag_to_chef_version(cookbook_name, version_tag)
  version_name = version_tag.name.gsub(/^v/, '')
  {
    url: "/cookbooks/#{cookbook_name}/#{version_name}",
    version: version_name,
  }
end
