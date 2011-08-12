require File.expand_path('../lib/active_shard/version', __FILE__)

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'active_shrad'
  s.version     = ActiveShard::VERSION
  s.summary     = 'Sharding library for ActiveRecord'
  s.description = 'ActiveShard is a library that implements flexible sharding in ActiveRecord and Rails.'

  s.required_ruby_version     = '>= 1.8.7'
  s.required_rubygems_version = ">= 1.3.6"

  s.author            = 'Brasten Sager'
  s.email             = 'brasten@brasten.me'

  s.files             = Dir[ 'CHANGELOG', 'README.rdoc', 'lib/**/{*,.[a-z]*}' ]
  s.require_path      = 'lib'
  s.extra_rdoc_files  = %w( README.rdoc )
  
  s.add_dependency('activerecord',   '>= 3.0.0')
end