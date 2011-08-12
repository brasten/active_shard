require 'active_shard/exceptions'

module ActiveShard

  autoload :ShardDefinition, 'active_shard/shard_definition'

  # Represents a group of shards. Most commonly used to group shards belonging to
  # the same schema.
  #
  # Handles some basic caching of common use cases to (hopefully) increase performance
  # in most situations.
  #
  class ShardCollection

    # Initializes a shard group
    #
    # @param [Array<ShardDefinition>] shard_definitions
    #
    def initialize( shard_definitions=[] )
      add_shards( shard_definitions )
    end

    # Returns a Shard Definition by the shard name
    #
    # @return [ShardDefinition]
    #
    def shard( name )
      definitions_by_name[ name.to_sym ]
    end

    # Adds a list of shard definitions to this collection.
    #
    # @return [Array] a list of shards that were added
    #
    def add_shards( shard_definitions )
      added_shards = []

      shard_definitions.each do |definition|
        begin
          added_shards << add_shard( definition )
        rescue NameNotUniqueError
          # bury
        end
      end

      added_shards
    end

    # Adds a shard definition to the collection
    #
    # @return [ShardDefinition] added shard definition
    #
    def add_shard( *args )
      shard_def = ( args.first.is_a?(ShardDefinition) ? args.first : ShardDefinition.new( *args ) )

      duplicate_exists = shard_name_exists?( shard_def.name )

      raise NameNotUniqueError,
            "Shard named '#{shard_def.name.to_s}' exists for schema '#{shard_def.schema.to_s}'" if duplicate_exists

      definitions << shard_def
      definitions_by_schema( shard_def.schema ) << shard_def
      definitions_by_name[ shard_def.name.to_sym ] = shard_def

      shard_def
    end

    # All shard definitions in collection
    #
    # @return [Array<ShardDefinition>] shard definitions
    #
    def shard_definitions
      definitions.dup
    end

    # Returns a ShardCollection with definitions from this collection
    # that match the provided schema name
    #
    # @param [Symbol] schema_name schema name
    #
    # @return [ShardCollection] collection containing applicable definitions
    #
    def by_schema( schema_name )
      self.class.new( definitions_by_schema( schema_name ) )
    end

    # Removes a shard definition from the collection based on the
    # provided shard name.
    #
    # @param [Symbol] shard_name
    #
    # @return [ShardDefinition,nil] the ShardDefinition removed, or
    #   nil if none was found
    #
    def remove_shard( shard_name )
      shard_def = definitions_by_name.delete( shard_name.to_sym )
      return nil if shard_def.nil?

      definitions.delete( shard_def )
      definitions_by_schema( shard_def.schema ).delete( shard_def )

      shard_def
    end

    # Returns whether or not a Shard exists in this collection with the provided
    # schema and shard names.
    #
    # @return [Boolean]
    #
    def shard_name_exists?( shard_name )
      !( definitions_by_name[ shard_name.to_sym ].nil? )
    end

    # Returns a random shard name from the group
    #
    # @return [Symbol] a shard name
    #
    def any_shard
      definitions[ rand( definitions.size ) ].name
    end

    private

      def definitions
        @definitions ||= []
      end

      def definitions_by_schema( schema_name )
        ( @definitions_by_schema ||= {} )[ schema_name.nil? ? nil : schema_name.to_sym ] ||= []
      end

      def definitions_by_name
        ( @definitions_by_name ||= {} )
      end

  end
end