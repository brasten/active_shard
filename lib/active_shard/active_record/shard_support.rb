module ActiveShard
  module ActiveRecord

    # To enable ActiveShard support in ActiveRecord, mix this module in to your
    # model superclass.
    #
    # eg: ActiveRecord::Base.send( :include, ActiveShard::ActiveRecord::ShardSupport )
    #
    # For an explanation of why you'd use ShardedBase or ShardSupport, @see ActiveShard::ActiveRecord
    #
    module ShardSupport

      def self.included( base )
        base.extend( ClassMethods )
      end

      module ClassMethods
        
        # Specifies the schema name for the current model class (and its subclasses)
        #
        def schema_name( schema_name=:not_specified )
          write_inheritable_attribute( :schema_name, schema_name ) unless ( schema_name == :not_specified )
          read_inheritable_attribute( :schema_name )
        end
      end

    end

  end
end