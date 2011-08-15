require File.expand_path('../lib/active_shard/version', __FILE__)

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'active_shard'
  s.version     = ActiveShard::VERSION
  s.summary     = 'Sharding library for ActiveRecord'
  s.description = 'ActiveShard is a library that implements flexible sharding in ActiveRecord and Rails.'

  s.required_ruby_version     = '>= 1.8.7'
  s.required_rubygems_version = ">= 1.3.6"

  s.authors             = ['Brasten Sager', 'Matt Baker']
  s.email               = ['brasten@dashwire.com', 'matt@dashwire.com']

  s.files             = Dir[ 'CHANGELOG', 'README.md', 'lib/**/*.rb' ]
  s.require_path      = 'lib'
end