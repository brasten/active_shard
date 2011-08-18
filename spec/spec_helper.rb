
$: << File.expand_path( '..', __FILE__ ) # spec
$: << File.expand_path( '../../lib', __FILE__ ) # lib

require 'active_shard'
require 'fileutils'
require 'pathname'

ARTIFACTS_PATH = Pathname.new( File.expand_path('../artifacts', __FILE__) )

RSpec.configure do |config|
  # Allows selection of a single group/example by adding ":focus => true" meta
  # config.filter_run :focus => true
  # config.run_all_when_everything_filtered = true

  config.around(:each) do |ex|
    if ex.metadata[ :artifacts ]
      ARTIFACTS_PATH.rmtree if File.exists?( ARTIFACTS_PATH )
      ARTIFACTS_PATH.mkpath unless File.exists?( ARTIFACTS_PATH )
      ex.run
      ARTIFACTS_PATH.rmtree if File.exists?( ARTIFACTS_PATH )
    else
      ex.run
    end
  end

  config.around(:all) do |ex|
    ActiveShard.with_environment( :test ) do
      ActiveShard.with( :directories => :directory, :main => :db1 ) do
        ex.run
      end
    end
  end
end