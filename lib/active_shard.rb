require 'active_support'

module ActiveShard
  extend ActiveSupport::Autoload

  autoload :Config
  autoload :Scope
  autoload :ScopeManager
  autoload :ShardCollection
  autoload :ShardDefinition
  autoload :ShardLookupHandler

  class << self

    def with_environment( val )
      previous_environment = self.environment
      self.environment = val

      yield

      self.environment = previous_environment
    end

    def environment=( val )
      env_changed = !( @environment.to_s == val.to_s )

      @environment = val.nil? ? nil : val.to_sym

      reload_observer_shards! if env_changed
    end

    def environment
      @environment
    end

    # Returns the current Config object for ActiveShard.
    #
    # @yield [c] yields the current config object to the block for setup
    #
    # @return [Config] current config
    #
    def config
      @config ||= Config.new

      yield( @config ) if block_given?

      @config
    end

    def base_schema_name=(val)
      @base_schema_name = val.nil? ? nil : val.to_sym
    end

    def base_schema_name
      @base_schema_name
    end

    def shard_configuration=( configuration )
      config.shard_configuration=( configuration )

      reload_observer_shards!
    end

    # Doesn't yet support anything other than ActiveRecord::Base
    #
    #def base_class=(val)
    #  @base_class = val
    #end
    #
    #def base_class
    #  @base_class
    #end

    def notify_shard_observers( message, *args )
      shard_observers.each do |observer|
        observer.public_send( message, *args ) if observer.respond_to?( message )
      end
    end

    def add_shard_observer( observer )
      shard_observers << observer
    end

    def shard_observers
      @shard_observers ||= []
    end

    def add_shard( *args )
      definition = args.first.is_a?( ShardDefinition ) ? args.first : ShardDefinition.new( *args )

      config.add_shard( environment, definition )

      notify_shard_observers( :add_shard, definition )

      definition
    end

    def remove_shard( shard_name )
      config.remove_shard( environment, shard_name )

      notify_shard_observers( :remove_shard, shard_name )
    end

    def shard_definitions
      config.shard_definitions( environment )
    end

    def shard( shard_name )
      config.shard( environment, shard_name )
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

    def reload_observer_shards!
      notify_shard_observers( :remove_all_shards! )
      notify_shard_observers( :add_shards, shard_definitions )
    end

  end
end

ActiveSupport.run_load_hooks(:active_shard, ActiveShard) if defined?(ActiveSupport)