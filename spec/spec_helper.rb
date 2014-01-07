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

def prepare_cookbook(path, versions)
  # Initialise our test repo
  repo = Git.init(path)
  
  # Add dummy data
  Dir.chdir(path) do
    versions.each do |version|
      FileUtils.touch("tmp")
      repo.add('tmp')
      repo.commit(version)
      repo.add_tag("v#{version}")
    end
  end
  
  # Finalise the structure
  FileUtils.mv(File.join(path, ".git"), "#{path}.git")
  FileUtils.rmdir(path)
end

# For RSpec 2.x
RSpec.configure do |c|
  c.include RSpecMixin
  c.alias_it_should_behave_like_to :should_behave_like, 'should behave like'
end
