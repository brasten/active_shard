module ActiveShard

  autoload :Config,               'active_shard/config'
  autoload :ScopeManager,         'active_shard/scope_manager'
  autoload :ShardLookupHandler,   'active_shard/shard_lookup_handler'
  autoload :ShardCollection,      'active_shard/shard_collection'
  autoload :ShardDefinition,      'active_shard/shard_definition'

  class << self

    # Returns the current Config object for ActiveShard.
    #
    # @yield [c] yields the current config object to the block for setup
    #
    # @return [Config] current config
    #
    def config()
      @config ||= Config.new

      yield( @config ) if block_given?

      @config
    end

    # Sets the current scope handling object.
    #
    # Scope handler must respond to the following methods:
    #   #push( scope ), #pop( scopes ), #active_shard_for_schema( schema )
    #
    def scope=( val )
      @scope = val
    end

    # Returns current scope object
    #
    # @return [#push,#pop,#active_shard_for_schema] current scope object
    #
    def scope
      @scope ||= ScopeManager.new
    end

    # Sets the active shards before yielding, and reverts them before returning.
    #
    # This method will also pop off any additional scopes that were added by the
    # provided block if they were not already popped.
    #
    # @example
    #
    #   ActiveShard.with( :users => :user_db1 ) do
    #     ActiveShard.with( :users => :user_db2 ) do
    #       ActiveShard.activate_shards( :users => :user_db3 )
    #       # 3 shard entries on scope stack
    #     end
    #     # 1 shard entry on scope stack
    #   end
    #
    # @param [Hash] scopes schemas (keys) and active shards (values)
    #
    # @return the return value from the provided block
    #
    def with( scopes={}, &block )
      ret = nil

      begin
        activate_shards( scopes )

        ret = block.call()
      ensure
        pop_to( scopes )
        ret
      end
    end

    # Pushes active shards onto the scope without a block.
    #
    def activate_shards( scopes={} )
      scope.push( scopes )
    end

    def pop_to( scopes )
      scope.pop( scopes )
    end

    def shards_by_schema( schema_name )
      config.shards_by_schema( schema_name )
    end

    def logger
      @logger
    end

    def logger=(val)
      @logger = val
    end

  end
end

ActiveSupport.run_load_hooks(:active_shard, ActiveShard) if defined?(ActiveSupport)