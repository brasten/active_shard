require 'active_shard/exceptions'

module ActiveShard
  module ActiveRecord
    class SchemaConnectionAdapter

      delegate :columns, :verify, :verify!, :run_callbacks, :quote_table_name, :quote_value, :quote, :to => :adapter

      def initialize( adapter )
        @adapter = adapter
      end

      def method_missing( sym, *args, &block )
        raise ::ActiveShard::NoActiveShardError
      end

      private
        def adapter
          @adapter
        end
    end
  end
end