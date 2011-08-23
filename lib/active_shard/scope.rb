module ActiveShard

  # Maintains the state of current active shards per schema.
  #
  # Requests for the current active shard for a schema name will iterate
  # up the scope stack until it finds an active shard (or nil).
  #
  # @example
  #   scope = Scope.new
  #   scope.push( :user_data => :db_1, :directories => :directory_1 )
  #
  #   # updates current :user_data shard, :directories shard remains
  #   scope.push( :user_data => :db_3 )
  #
  #   scope.active_shard_for_schema( :user_data )
  #   => :db_3
  #
  #   scope.active_shard_for_schema( :directories )
  #   => :directory_1
  #
  class Scope

    def initialize
      @scope_crumbs   = []
      @current_shards = {}
    end

    # Push a new scope on onto the stack.
    #
    # The active_shards parameter should be a hash with schema names for
    # keys and shard names for the corresponding values.
    #
    # eg: scope.push( :directory => :dir1, :user_data => :db1 )
    #
    # @param [Hash] active_shards
    #
    def push( active_shards )
      scope_crumbs << active_shards

      # shortcutting #build_current_shards for performance reasons
      if active_shards.is_a?(Symbol)
        # if active_shards is a Symbol, ALL schemas are using active shard
        current_shards.keys.each do |schema|
          current_shards[schema] = active_shards
        end
        current_shards[AnyShard] = active_shards

      else
        current_shards.merge!( normalize_keys( active_shards ) )
      end
    end

    # Remove the last scope from the stack
    #
    # FIXME: Symbols (for AnySchema) may not roll back properly if multiple
    #        the same symbol is on the stack several times
    #
    def pop( pop_until=nil )
      if pop_until.nil?
        scope_crumbs.pop
      else
        (scope_crumbs.size - (scope_crumbs.index(pop_until) || (scope_crumbs.size - 1))).times do
          scope_crumbs.pop
        end
      end

      build_current_shards( scope_crumbs )
    end

    # Returns the name of the active shard by the provided schema name.
    #
    # @param [Symbol] schema_name name of schema
    #
    # @return [Symbol, nil] current active shard for schema
    #
    def active_shard_for_schema( schema_name )
      current_shards[ schema_name.to_sym ] || current_shards[ AnyShard ]
    end

    private

      # scope_crumbs and current_shards are two different data structures that
      # essentially represent the same data. "current_shards" is used for performance
      # when possible; "scope_crumbs" is used to generate current_shards when
      # necessary.

      attr_reader :scope_crumbs
      attr_reader :current_shards

      def build_current_shards( crumbs )
        current_shards.clear

        crumbs.each do |crumb|
          case crumb
          when Symbol

            current_shards.keys.each do |schema|
              current_shards[schema] = crumb
            end
            current_shards[AnyShard] = crumb
          when Hash

            crumb.each_pair { |schema, shard| current_shards[ schema.to_sym ] = shard.to_sym }
          end
        end

        current_shards
      end

      def normalize_keys( hash )
        ret = {}

        hash.each_pair { |k, v| ret[ k.to_sym ] = v }

        ret
      end

      class AnyShard; end

  end
end