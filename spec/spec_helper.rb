require 'rack/test'
require 'rspec'
require 'tmpdir'

require 'cookbook_server'

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

def prepare_bare_repository(root, name, versions)
  # Initialise our test repo
  path = File.join(root, name)
  repo = Git.init(path)
  
  yield repo
  
  # Convert our working directory's repo to a bare repo
  repo.config('core.bare', true)
  FileUtils.mv(File.join(path, ".git"), "#{path}.git")
  FileUtils.rmdir(path)
end

def write_repository_file(repo, filepath, content)
  if 'true' == repo.config('core.bare')
    raise ArgumentError, "Repo #{repo.dir.to_s} is already bare and cannot be worked with directly", [repo.dir.to_s]
  end
  Dir.chdir(repo.dir.to_s) do
    File.open(filepath, 'w') do |f|
      f.puts content
    end
  end
end

# For RSpec 2.x
RSpec.configure do |c|
  c.include RSpecMixin
  c.alias_it_should_behave_like_to :behaves_like, 'behaves like'
end
