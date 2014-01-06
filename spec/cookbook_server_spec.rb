# spec/app_spec.rb
require 'json'

require File.expand_path '../spec_helper.rb', __FILE__

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :should_behave_like, 'should behave like'
end

shared_examples 'JSON' do
  it 'should return a JSON Content-Type header' do
    get subject
    last_response.headers['Content-Type'].should match(%r{application/json\b})
  end

  it 'should return valid JSON' do
    get subject
    expect { JSON.parse last_response.body }.not_to raise_error
  end
end

describe '/cookbooks' do
  subject { '/cookbooks' }
  should_behave_like 'JSON'
end
