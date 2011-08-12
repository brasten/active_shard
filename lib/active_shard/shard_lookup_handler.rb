module ActiveShard

  # Handles current and schema shard resolution using the current
  # scope and
  class ShardLookupHandler

    # Initializes a shard lookup handler
    #
    # @param [Hash] options
    # @option options [Scope,ScopeManager] :scope
    # @option options [Config] :config
    #   scope instances
    #
    def initialize( options={} )
      @scope  = options[:scope]
      @config = options[:config]
    end

    def lookup_active_shard( schema_name )
      @scope.active_shard_for_schema( schema_name )
    end

    def lookup_schema_shard( schema_name )
      @config.schema_shard_name_by_schema( schema_name )
    end

  end
end