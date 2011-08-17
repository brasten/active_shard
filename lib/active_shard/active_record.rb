require 'active_record'

module ActiveShard

  # The ActiveShard::ActiveRecord module contains the code necessary for ActiveRecord
  # integration.
  #
  # -- Need to add explanation of ShardedBase VS ShardSupport --
  #
  module ActiveRecord
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :ConnectionHandler
      autoload :ConnectionProxyPool
      autoload :ConnectionSpecificationAdapter
      autoload :SchemaConnectionProxy
      autoload :ShardSupport
      autoload :ShardedBase
    end

  end
end