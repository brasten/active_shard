module ActiveShard

  # Handles current shard resolution using the provided scope
  #
  class ShardLookupHandler

    # Initializes a shard lookup handler
    #
    # @param [Hash] options
    # @option options [Scope,ScopeManager] :scope
    #
    def initialize( options={} )
      @scope  = options[:scope]
    end

    # Returns the active shard for the provided schema, or nil if none.
    #
    # @param [Symbol] schema_name
    # @return [Symbol, nil] shard name if any
    #
    def lookup_active_shard( schema_name )
      @scope.active_shard_for_schema( schema_name )
    end

  end
end