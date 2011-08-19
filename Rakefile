require 'rspec/core'
require 'rspec/core/rake_task'
require 'rubygems/package_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
end

task :default => :spec

namespace :gem do

  spec = Gem::Specification.load( 'active_shard.gemspec' )

  Gem::PackageTask.new(spec) do
    # defaults are fine, thanks!
  end

  desc "release active_shard-#{spec.version}.gem"
  task :release => :package do
    sh("gem push -k dashwire_api_key 'pkg/active_shard-#{spec.version}.gem'")
  end
end
