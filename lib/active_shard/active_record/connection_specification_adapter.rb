module ActiveShard
  module ActiveRecord

    class ConnectionSpecificationAdapter

      # @param [ShardDefinition] shard_definition
      #
      def initialize( shard_definition )
        @shard_definition = shard_definition
      end

      def adapter_method
        "#{shard_definition.connection_spec[:adapter]}_connection"
      end

      def config
        shard_definition.connection_spec
      end

      ##### non-connection_spec related methods #####

      def shard_name
        shard_definition.name
      end

      private

        attr_reader :shard_definition

    end

  end
end