require File.expand_path('../lib/active_shard/version', __FILE__)

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'active_shard'
  s.version     = ActiveShard::VERSION
  s.summary     = 'Sharding library for ActiveRecord'
  s.description = 'ActiveShard is a library that implements flexible sharding in ActiveRecord and Rails.'
  s.homepage    = 'https://github.com/dashwire/active_shard'

  s.required_ruby_version     = '>= 1.8.7'
  s.required_rubygems_version = ">= 1.3.6"

  s.authors             = ['Brasten Sager', 'Matt Baker']
  s.email               = ['brasten@dashwire.com', 'matt@dashwire.com']

  s.files               = Dir[ 'README.md', 'lib/**/*.rb' ]
  s.require_path        = 'lib'

  s.add_dependency      "activesupport", "~> 3.0.0"
end