module ActiveShard

  autoload :Scope, 'active_shard/scope'

  # ScopeManager handles the passing of messages to a Scope based on
  # the current thread.
  #
  # Allows consumers to operate on a Scope duck-typed object without
  # handling the Thread local variable stuff.
  #
  class ScopeManager

    # Initializes a scope manager
    #
    # @param [Hash] options
    # @option options [Class,#new] :scope_class class to use when instantiating
    #   scope instances
    #
    def initialize( options={} )
      self.scope_class = options[:scope_class] if options[:scope_class]
    end

    # @see ActiveShard::Scope#push
    #
    def push( *args )
      scope.push( *args )
    end

    # @see ActiveShard::Scope#pop
    #
    def pop( *args )
      scope.pop( *args )
    end

    # @see ActiveShard::Scope#active_shard_for_schema
    #
    def active_shard_for_schema( *args )
      scope.active_shard_for_schema( *args )
    end

    # Sets the class to use for maintaining Thread-local scopes
    #
    # Instances of klass must respond to:
    #   #push
    #   #pop
    #   #active_shard_for_schema
    #
    # @param [Class,#new] klass scope_class
    #
    def scope_class=( klass )
      @scope_class = klass
    end

    # Returns the current scope_class
    #
    def scope_class
      @scope_class ||= Scope
    end

    private
      def scope
        Thread.current[:active_shard_scope] ||= scope_class.new
      end

  end
end