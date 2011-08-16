require 'active_record'
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
      # @option options [ShardLookupHandler, #lookup_active_shard] :shard_lookup
      #
      def initialize( shard_definitions, options={} )
        @shard_lookup = options[ :shard_lookup ]

        @connection_pools = {}
        @schema_pools     = {}

        initialize_shard_definitions( shard_definitions )
      end

      def initialize_shard_definitions( definitions )
        definitions.each do |definition|
          schema_pools[ definition.schema.to_sym ] ||= new_schema_pool( definition )


          connection_pools[ connection_pool_id( definition.schema, definition.name ) ] = new_connection_pool( definition )
        end
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
            schema_pools[ schema_name.to_sym ] :
            connection_pools[ connection_pool_id( schema_name, active_shard_name ) ] )
      end

      private

        attr_reader :schema_pools

        def new_schema_pool( definition )
          schema_pool_class.new(
              connection_specification_class.new( definition.connection_spec, definition.adapter_method )
            )
        end

        def new_connection_pool( definition )
          connection_pool_class.new(
            connection_specification_class.new( definition.connection_spec, definition.adapter_method )
          )
        end

        def connection_pool_class
          ::ActiveRecord::ConnectionAdapters::ConnectionPool
        end

        def schema_pool_class
          SchemaConnectionPool
        end

        def connection_specification_class
          ::ActiveRecord::Base::ConnectionSpecification
        end

        def connection_pool_id( schema_name, shard_name )
          "#{schema_name.to_s}+#{shard_name.to_s}".to_sym
        end


    end
  end
end
