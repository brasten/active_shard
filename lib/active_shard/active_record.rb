require 'active_record'

module ActiveShard

  # The ActiveShard::ActiveRecord module contains the code necessary for ActiveRecord
  # integration.
  #
  # -- Need to add explanation of ShardedBase VS ShardSupport --
  #
  module ActiveRecord

    autoload :ConnectionHandler,        'active_shard/active_record/connection_handler'
    autoload :ConnectionProxyPool,      'active_shard/active_record/connection_proxy_pool'
    autoload :ConnectionSpecificationAdapter,
             'active_shard/active_record/connection_specification_adapter'
    autoload :SchemaConnectionProxy,    'active_shard/active_record/schema_connection_proxy'
    autoload :ShardSupport,             'active_shard/active_record/shard_support'
    autoload :ShardedBase,              'active_shard/active_record/sharded_base'

  end
end