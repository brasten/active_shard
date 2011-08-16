module ActiveShard
  module ActiveRecord
    class PoolFactory

      attr_accessor :connection_pool_class
      attr_accessor :schema_pool_class

      # Initializes a new PoolFactory
      #
      # @param [Hash] options
      # @option options [Class] connection_pool_class
      # @option options [Class] schema_pool_class
      #
      def initialize( options={} )
        @connection_pool_class = options[:connection_pool_class]
        @schema_pool_class     = options[:schema_pool_class]
      end


      def create_connection_pool( definition )
        
      end

      def create_schema_pool( definition )

      end

    end
  end
end