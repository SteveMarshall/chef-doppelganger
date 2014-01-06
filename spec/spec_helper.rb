require 'rack/test'

require File.expand_path '../../cookbook_server.rb', __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
end

# For RSpec 2.x
RSpec.configure do |c|
  c.include RSpecMixin
  c.alias_it_should_behave_like_to :should_behave_like, 'should behave like'
end
