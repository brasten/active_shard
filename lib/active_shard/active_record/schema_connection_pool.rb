require 'active_record/connection_adapters/abstract/connection_pool'

module ActiveShard
  module ActiveRecord

    autoload :SchemaConnectionAdapter, 'active_shard/active_record/schema_connection_adapter'

    class SchemaConnectionPool < ::ActiveRecord::ConnectionAdapters::ConnectionPool

      private
        def new_connection
          SchemaConnectionAdapter.new( super )
        end

    end

  end
end
