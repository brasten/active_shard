module ActiveShard
  autoload :ShardDefinition,    'active_shard/shard_definition'
  autoload :ShardCollection,    'active_shard/shard_collection'

  class Config

    # Returns a filtered list of shards that belong to
    # the specified schema
    #
    # @return [Array] shards belonging to schema
    #
    def shards_by_schema( schema_name )
      shard_collection.by_schema( schema_name )
    end

    # Returns the name of a shard usable for schema definition
    # connections
    #
    def schema_shard_name_by_schema( schema_name )
      shard_def = shard_definitions_by_schema( schema_name ).first

      shard_def.nil? ? nil : shard_def.name.to_sym
    end

    # Returns a Shard Definition by the shard name
    #
    # @return [ShardDefinition]
    #
    def shard( name )
      shard_collection.shard( name )
    end

    def add_shard( *args )
      shard_collection.add_shard( *args )
    end

    def shard_definitions
      shard_collection.shard_definitions
    end

    def remove_shard( shard_name )
      shard_collection.remove_shard( shard_name )
    end

    private
      def shard_collection
        @shard_collection ||= ShardCollection.new
      end

  end
  
end