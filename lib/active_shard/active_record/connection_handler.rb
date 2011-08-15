require 'active_record/connection_adapters/abstract/connection_pool'

module ActiveShard
  module ActiveRecord

    autoload :SchemaConnectionPool, 'active_shard/active_record/schema_connection_pool'

    class ConnectionHandler < ::ActiveRecord::ConnectionAdapters::ConnectionHandler

      # Used to look up shard names
      #
      attr_accessor :shard_lookup

      # Initializes a new ConnectionHandler
      #
      # @param [Array<ShardDefinition>] shard_definitions
      # @param [Hash] options
      # @option options [ShardLookupHandler] :shard_lookup
      #
      def initialize( shard_definitions, options={} )
        @shard_lookup = options[ :shard_lookup ]

        @connection_pools = {}
        @schema_pools     = {}

        initialize_shard_definitions( shard_definitions )
      end

      def initialize_shard_definitions( definitions )
        definitions.each do |definition|
          schema_pools[ definition.schema.to_sym ] ||= SchemaConnectionPool.new(
              ::ActiveRecord::Base::ConnectionSpecification.new( definition.connection_spec, definition.adapter_method )
            )


          connection_pools[ connection_pool_id( definition.schema, definition.name ) ] =
            ::ActiveRecord::ConnectionAdapters::ConnectionPool.new(
              ::ActiveRecord::Base::ConnectionSpecification.new( definition.connection_spec, definition.adapter_method )
            )
        end
      end

      #def establish_connection( *args )
      #  raise NoMethodError, "Sharded models do not support establish_connection"
      #end

      # Retrieve connection pool for class
      #
      def retrieve_connection_pool( klass )
        schema_name = klass.schema_name

        active_shard_name = shard_lookup.lookup_active_shard( schema_name )
        
        ( active_shard_name.nil? ?
            schema_pools[ schema_name.to_sym ] :
            connection_pools[ connection_pool_id( schema_name, active_shard_name ) ] )
      end

      private

        attr_reader :schema_pools

        def connection_pool_id( schema_name, shard_name )
          "#{schema_name.to_s}+#{shard_name.to_s}".to_sym
        end


    end
  end
end
