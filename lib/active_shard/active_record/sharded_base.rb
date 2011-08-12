require 'active_record/base'
require 'active_shard/active_record/shard_support'

module ActiveShard
  module ActiveRecord

    # ShardedBase is a subclass of ActiveRecord::Base which mixes in the ShardSupport
    # module.
    #
    # For an explanation of why you'd use ShardedBase or ShardSupport, @see ActiveShard::ActiveRecord
    #
    class ShardedBase < ::ActiveRecord::Base
      include ::ActiveShard::ActiveRecord::ShardSupport
      
    end

  end
end