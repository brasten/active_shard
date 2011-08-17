require 'active_record'
require 'active_record/connection_adapters/abstract/connection_pool'

module ActiveShard
  module ActiveRecord

    class ConnectionHandler < ::ActiveRecord::ConnectionAdapters::ConnectionHandler

      # Used to look up shard names
      #
      attr_accessor :shard_lookup

      # Initializes a new ConnectionHandler
      #
      # @param [Array<ShardDefinition>] shard_definitions
      # @param [Hash] options
      # @option options [ShardLookupHandler, #lookup_active_shard] :shard_lookup
      #
      def initialize( options={} )
        @shard_lookup = options[ :shard_lookup ]

        @shard_definitions = []
        @connection_pools = {}
        @schema_pools     = {}
      end

      # @api ShardObserver
      def add_shards( shard_definitions )
        shard_definitions.each( &method(:add_shard) )
      end

      # @api ShardObserver
      def add_shard( shard_definition )
        connection_pools[ connection_pool_id( shard_definition ) ] = new_connection_pool( shard_definition )
        shard_definitions << shard_definition

        self
      end

      # @api ShardObserver
      def remove_shard( shard_definition )
        schema_name = shard_definition.schema

        # Remove SchemaPool if it's based on this shard
        #
        if ( schema_pools[ schema_name ] && schema_pools[ schema_name ].shard_definition == shard_definition )
          schema_pools[ schema_name ].disconnect!
          schema_pools.delete( schema_name )
        end

        pool_id = connection_pool_id( shard_definition )

        # Remove connection pool
        connection_pools[ pool_id ].disconnect!
        connection_pools.delete( pool_id )

        shard_definitions.delete( shard_definition )

        self
      end

      # @api ShardObserver
      def remove_all_shards!
        defs = shard_definitions.dup

        defs.each( &method(:remove_shard) )
      end

      # I want to put this in here, but it seems to cause problems that I haven't yet tracked down. [BLS]
      #
      #def establish_connection( *args )
      #  raise NoMethodError, "Sharded models do not support establish_connection"
      #end

      # Retrieve connection pool for class
      #
      # @param [#schema_name] klass An object which responds to #schema_name
      # @return [ConnectionPool,SchemaConnectionPool] connection pool
      #
      def retrieve_connection_pool( klass )
        schema_name = ( sn = klass.schema_name ).nil? ? nil : sn.to_sym

        active_shard_name = shard_lookup.lookup_active_shard( schema_name )
        
        ( active_shard_name.nil? ?
            get_schema_pool_for( schema_name ) :
            connection_pools[ connection_pool_id( schema_name, active_shard_name ) ] )
      end

      private

        attr_reader :schema_pools
        attr_reader :shard_definitions

        def get_schema_pool_for( schema_name )
          schema_name = schema_name.nil? ? nil : schema_name.to_sym
          
          schema_pools[ schema_name ] ||= new_schema_pool( shard_definitions_for_schema( schema_name ).first )
        end

        def new_schema_pool( definition )
          ConnectionProxyPool.new( definition, :proxy_class => SchemaConnectionProxy )
        end

        def new_connection_pool( definition )
          ConnectionProxyPool.new( definition )
        end

        def shard_definitions_for_schema( schema_name )
          shard_definitions.find_all { |sd| sd.belongs_to_schema?( schema_name ) }
        end

        # args are either a ShardDefinition or a schema and shard name.
        #
        def connection_pool_id( *args )
          definition = args.first.is_a?( ShardDefinition ) ? args.shift : nil

          schema_name = definition.nil? ? args.shift : definition.schema
          shard_name  = definition.nil? ? args.shift : definition.name

          "#{schema_name.to_s}+#{shard_name.to_s}".to_sym
        end


    end
  end
end
