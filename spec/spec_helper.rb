require 'rack/test'
require 'tmpdir'

require File.expand_path '../../cookbook_server.rb', __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
end

def in_temp_dir()
  Dir.mktmpdir('cookbook_server_test') do |tmp_path|
    Dir.chdir(tmp_path) do
      yield tmp_path
    end
  end
end

# For RSpec 2.x
RSpec.configure do |c|
  c.include RSpecMixin
  c.alias_it_should_behave_like_to :should_behave_like, 'should behave like'
end
