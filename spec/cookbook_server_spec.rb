# spec/app_spec.rb
require 'git'
require 'json'
require 'fileutils'

require File.expand_path '../spec_helper.rb', __FILE__

shared_examples 'JSON' do
  it 'returns a JSON Content-Type header' do
    get subject
    last_response.headers['Content-Type'].should match(%r{^application/json\b})
  end

  it 'returns valid JSON' do
    get subject
    expect { JSON.parse last_response.body }.not_to raise_error
  end
end

shared_examples "a cookbook" do |versions|
  in_temp_dir do |tmp_path|
    before(:all) do
      @name = 'test'
      app.set :cookbook_store, tmp_path
      prepare_cookbook(File.join(tmp_path, @name), versions)
    end

    it "returns the cookbook in a hash with URL and #{versions.length} version(s)" do
      get subject
      result = JSON.parse(last_response.body)
      
      result.should have_key(@name)
      result[@name]["url"].should eq("/cookbooks/#{@name}")
      
      result[@name]['versions'].should be_instance_of(Array)
      result[@name]['versions'].length.should eq(versions.length)
      versions.each do |version|
        result[@name]['versions'].should include({
          "url" => "/cookbooks/#{@name}/#{version}",
          "version" => version
        })
      end
    end

    it "lists versions in descending order" do
      get subject
      # Use Gem::Version for ordering so 0.2 < 0.10
      descending_versions = versions.sort_by{ |version|
        Gem::Version.new(version)
      }.reverse
      
      # Extract just the version numbers for comparison
      response_versions = JSON.parse(last_response.body)[@name]['versions']
      response_versions = response_versions.map { |version|
        version["version"]
      }
      response_versions.should eq(descending_versions)
    end
  end
end

describe 'with no cookbooks' do
  context '/cookbooks' do
    subject { '/cookbooks' }
    behaves_like 'JSON'

    it 'returns an empty hash' do
      get subject
      JSON.parse(last_response.body).should eq(Hash.new)
    end
  end
  
  context '/cookbooks/test' do
    subject { '/cookbooks/test' }

    it 'is not found' do
      get subject
      last_response.not_found?.should be_true
    end
  end
end

describe 'with a cookbook with 1 version' do
  versions = ['0.1.0']
  context '/cookbooks' do
    subject { '/cookbooks' }
    behaves_like 'JSON'
    behaves_like 'a cookbook', versions
  end

  context '/cookbooks/test' do
    subject { '/cookbooks/test' }
    behaves_like 'JSON'
    behaves_like 'a cookbook', versions
  end
end

describe 'with a cookbook with 3 versions' do
  versions = ['0.1.0', '0.2.0', '0.10.0']
  context '/cookbooks' do
    subject { '/cookbooks' }
    behaves_like 'JSON'
    behaves_like 'a cookbook', versions
  end

  context '/cookbooks/test' do
    subject { '/cookbooks/test' }
    behaves_like 'JSON'
    behaves_like 'a cookbook', versions
  end
end
