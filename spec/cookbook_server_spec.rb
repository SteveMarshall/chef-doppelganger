# spec/app_spec.rb
require 'git'
require 'json'
require 'fileutils'

require File.expand_path '../spec_helper.rb', __FILE__

shared_examples 'JSON' do
  it 'should return a JSON Content-Type header' do
    get subject
    last_response.headers['Content-Type'].should match(%r{^application/json\b})
  end

  it 'should return valid JSON' do
    get subject
    expect { JSON.parse last_response.body }.not_to raise_error
  end
end

describe '/cookbooks' do
  subject { '/cookbooks' }
  should_behave_like 'JSON'

  context 'with no cookbooks' do
    it 'returns an empty hash' do
      get subject
      JSON.parse(last_response.body).should eq(Hash.new)
    end
  end

  context 'with a cookbook' do
    in_temp_dir do |tmp_path|
      before(:all) do
        app.set :cookbook_store, tmp_path
        @name = 'test'
        @version = '0.1.0'
        
        prepare_cookbook(File.join(tmp_path, @name), [@version])
      end

      it 'returns the cookbook in a hash with URL and versions' do
        get subject
        JSON.parse(last_response.body).should eq({
          @name => {
            "url" => "/cookbooks/#{@name}",
            "versions" => [{
              "url" => "/cookbooks/#{@name}/#{@version}",
              "version" => @version
            }]
          }
        })
      end
    end
  end
end
