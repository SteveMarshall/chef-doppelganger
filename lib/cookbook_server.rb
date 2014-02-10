#!/usr/bin/env ruby
# encoding: UTF-8

require 'git'
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

# Based on https://github.com/opscode/chef-zero/blob/master/lib/chef_zero/cookbook_data.rb#L66
class PretendCookbookMetadata < Hash
  def initialize(cookbook_name)
    self.name(cookbook_name)
    %w(attributes grouping dependencies supports recommendations suggestions
       conflicting providing replacing recipes).each do |hash_arg|
      self[hash_arg.to_sym] = Hash.new
    end
  end
  
  def method_missing(key, value = nil)
    unless value.nil?
      store key.to_sym, value
    end
  end
end

get '/cookbooks/:name/:version' do
  path = "#{settings.cookbook_store}/#{params[:name]}.git"
  pass unless Dir.exists?(path)
  
  repo = Git.bare(path)
  begin
    version = repo.tag("v#{params[:version]}")
  rescue Git::GitTagNameDoesNotExist
    pass
  end
  
  metadata = PretendCookbookMetadata.new(params[:name])
  repo.with_temp_working do
    repo.checkout_index(:all => true)
    repo.checkout(version)
    File.open('metadata.rb', 'r') do |metadata_file|
      metadata_contents = metadata_file.read
      metadata.instance_eval(metadata_contents, metadata_file.path)
    end
  end

  content_type :json
  {
    name: "#{params[:name]}-#{params[:version]}",
    cookbook_name: params[:name],
    version: params[:version],
    json_class:"Chef::CookbookVersion",
    metadata: metadata
  }.to_json
end

def render_cookbook(path)
  name = File.basename(path, ".git")
  repo = Git.bare(path)

  versions = repo.tags.map do |tag|
    tag_to_chef_version(name, tag)
  end
  # Use Gem::Version for comparison so 0.2 < 0.10
  descending_versions = versions.sort_by { |version|
    Gem::Version.new(version[:version])
  }.reverse

  {
    url: "/cookbooks/#{name}",
    versions: descending_versions,
  }
end

def tag_to_chef_version(cookbook_name, version_tag)
  version_name = version_tag.name.gsub(/^v/, '')
  {
    url: "/cookbooks/#{cookbook_name}/#{version_name}",
    version: version_name,
  }
end
