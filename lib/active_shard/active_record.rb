module ActiveShard

  # The ActiveShard::ActiveRecord module contains the code necessary for ActiveRecord
  # integration.
  #
  # -- Need to add explanation of ShardedBase VS ShardSupport --
  #
  module ActiveRecord
    
    autoload :ConnectionHandler,    'active_shard/active_record/connection_handler'
    autoload :ShardSupport,         'active_shard/active_record/shard_support'
    autoload :ShardedBase,          'active_shard/active_record/sharded_base'

  end
end

