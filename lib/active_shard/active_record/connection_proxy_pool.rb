require 'active_record'
require 'active_record/connection_adapters/abstract/connection_pool'

require 'active_shard/active_record/connection_specification_adapter'

module ActiveShard
  module ActiveRecord

    # ConnectionPool designed to return connection proxies of configurable types
    #
    class ConnectionProxyPool < ::ActiveRecord::ConnectionAdapters::ConnectionPool

      attr_reader :shard_definition

      # @param [ShardDefinition] definition
      # @param [Hash] options
      # @option options [Class] :proxy_class
      #
      def initialize( definition, options={} )
        super( ConnectionSpecificationAdapter.new( definition ) )

        @shard_definition = definition
        @proxy_class = options[:proxy_class]
      end

      private

        attr_reader :proxy_class

        def new_connection
          proxy_class.nil? ? super : proxy_class.new( super )
        end

    end

  end
end
