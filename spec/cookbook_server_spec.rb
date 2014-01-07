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
      expect(last_response.not_found?).to be_true
    end
  end
end

describe 'with a cookbook' do
  in_temp_dir do |tmp_path|
    before(:all) do
      app.set :cookbook_store, tmp_path
      @name = 'test'
      @version = '0.1.0'
      
      prepare_cookbook(File.join(tmp_path, @name), [@version])
    end

    shared_examples 'a single cookbook' do
      it 'returns the cookbook in a hash with URL and version' do
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

    context '/cookbooks' do
      subject { '/cookbooks' }
      behaves_like 'JSON'
      behaves_like 'a single cookbook'
    end

    context '/cookbooks/test' do
      subject { '/cookbooks/test' }
      behaves_like 'JSON'
      behaves_like 'a single cookbook'
    end
  end
end
