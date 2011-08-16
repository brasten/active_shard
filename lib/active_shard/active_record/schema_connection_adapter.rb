require 'active_shard/exceptions'

module ActiveShard
  module ActiveRecord
    class SchemaConnectionAdapter

      delegate :columns, :verify, :verify!, :run_callbacks, :quote_table_name, :quote_value, :quote, :to => :target

      def initialize( target )
        @target = target
      end

      def method_missing( sym, *args, &block )
        raise ::ActiveShard::NoActiveShardError
      end

      private
        def target
          @target
        end
    end
  end
end