require 'spec_helper'
require 'json'

# TODO: Test tags of the form X.Y.Z as well as vX.Y.Z

RSpec::Matchers.define :a_hash_like do |expected|
  match do |actual|
    # Only check the hash contains the keys/values we want to check
    # We don't care if it contains more, which is what equality does
    matches = true
    expected.each do |k,v|
      matches &&= (actual[k] == v)
    end
    matches
  end
  description do
    "a hash like #{expected}"
  end
end

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

shared_examples 'a cookbook version' do |cookbook_name, version|
  behaves_like 'JSON'

  it "returns basic metadata" do
    get subject
    result = JSON.parse(last_response.body)
    
    # TODO: Do we need other root properties?
    #       (chef_type=cookbook_version and frozen?)
    result['json_class'].should eq('Chef::CookbookVersion')
    result["cookbook_name"].should eq(cookbook_name)
    result["version"].should eq(version)
    result["name"].should eq("#{cookbook_name}-#{version}")
  end
  
  it 'returns metadata' do
    get subject
    result = JSON.parse(last_response.body)
    
    result['metadata']['name'].should eq(cookbook_name)
    result['metadata']['version'].should eq(version)
    result['metadata']['description'].should eq(@description)
  end
end

shared_examples "a cookbook" do |versions|
  behaves_like 'JSON'

  it "returns the cookbook in a hash with URL and #{versions.length} version(s)" do
    get subject
    result = JSON.parse(last_response.body)
    
    result.should have_key(@name)
    result[@name]["url"].should eq("/cookbooks/#{@name}")
    
    result[@name]['versions'].should be_instance_of(Array)
    result[@name]['versions'].length.should eq(versions.length)
    versions.each { |version|
      result[@name]['versions'].should include(a_hash_like({
        "url" => "/cookbooks/#{@name}/#{version}",
        "version" => version
      }))
    }
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

  it "provides a working link to itself" do
    get subject
    get JSON.parse(last_response.body)[@name]['url']
    last_response.should be_ok
  end
  
  it "provides working links to its versions" do
    get subject
    JSON.parse(last_response.body)[@name]['versions'].each do |version|
      get version['url']
      last_response.should be_ok
    end
  end

  versions.each do |version|
    context "/cookbooks/test/#{version}" do
      subject { "/cookbooks/test/#{version}" }
      behaves_like 'a cookbook version', 'test', version
    end

    unknown_version = Gem::Version.new(version).bump
    while versions.include?(unknown_version) do
      unknown_version = Gem::Version.new(version).bump
    end

    context "/cookbooks/test/#{unknown_version}" do
      subject { "/cookbooks/test/#{unknown_version}" }

      it 'is not found' do
        get subject
        last_response.should be_not_found
      end
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
      last_response.should be_not_found
    end
  end

  context '/cookbooks/test/0.1.0' do
    subject { '/cookbooks/test/0.1.0' }

    it 'is not found' do
      get subject
      last_response.should be_not_found
    end
  end
end

describe 'with a cookbook with 1 version' do
  in_temp_dir do |tmp_path|
    before(:all) do
      @name = 'test'
      @description = 'A test cookbook'
      app.set :cookbook_store, tmp_path
      prepare_bare_repository(tmp_path, @name) do |repo|
        write_repository_file(repo, "metadata.rb", <<-EOF
name    "#{@name}"
version "0.1.0"
description "#{@description}"
EOF
        )
        repo.add('metadata.rb')
        repo.commit('v0.1.0')
        repo.add_tag("v0.1.0")
      end
    end

    context '/cookbooks' do
      subject { '/cookbooks' }
      behaves_like 'a cookbook', ['0.1.0']
    end

    context '/cookbooks/test' do
      subject { '/cookbooks/test' }
      behaves_like 'a cookbook', ['0.1.0']
    end
  end
end

describe 'with a cookbook with 3 versions' do
  in_temp_dir do |tmp_path|
    versions = ['0.1.0', '0.2.0', '0.10.0']
    before(:all) do
      @name = 'test'
      @description = 'A test cookbook'
      app.set :cookbook_store, tmp_path
      prepare_bare_repository(tmp_path, @name) do |repo|
        versions.each do |version|
          write_repository_file(repo, "metadata.rb", <<-EOF
name    "#{@name}"
version "#{version}"
description "#{@description}"
EOF
          )
          repo.add('metadata.rb')
          repo.commit(version)
          repo.add_tag("v#{version}")
        end
      end
    end

    context '/cookbooks' do
      subject { '/cookbooks' }
      behaves_like 'a cookbook', versions
    end

    context '/cookbooks/test' do
      subject { '/cookbooks/test' }
      behaves_like 'a cookbook', versions
    end
  end
end

describe 'with a cookbook with evaluated metadata' do
  in_temp_dir do |tmp_path|
    before(:all) do
      @name = 'test'
      # HACK: Include \n here so IO.read doesn't add one and break the test
      @description = "An evaluated test cookbook\n"
      app.set :cookbook_store, tmp_path
      prepare_bare_repository(tmp_path, @name) do |repo|
        write_repository_file(repo, "README.md", @description)
        write_repository_file(repo, "metadata.rb", <<-EOF
name    "#{@name}"
version "0.1.0"
description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
EOF
        )
        repo.add(['README.md', 'metadata.rb'])
        repo.commit('v0.1.0')
        repo.add_tag("v0.1.0")
      end
    end

    context '/cookbooks' do
      subject { '/cookbooks' }
      behaves_like 'a cookbook', ['0.1.0']
    end

    context '/cookbooks/test' do
      subject { '/cookbooks/test' }
      behaves_like 'a cookbook', ['0.1.0']
    end
  end
end
