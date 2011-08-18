require 'active_shard/shard_collection'

module ActiveShard

  class Config

    def shard_configuration=( configuration )
      shard_collections.clear
      
      configuration.each_pair do |environment, shard_definitions|
        shard_collection( environment.to_sym ).add_shards( shard_definitions )
      end
    end

    def shards_by_schema( environment, schema )
      shard_collection( environment ).by_schema( schema )
    end

    def add_shard( environment, shard_definition )
      shard_collection( environment ).add_shard( shard_definition )
    end

    def shard_definitions( environment )
      shard_collection( environment )
    end

    def remove_shard( environment, shard_name )
      shard_collection( environment ).remove_shard( shard_name )
    end

    def shard( environment, shard_name )
      shard_collection( environment ).shard( shard_name )
    end

    private
      def shard_collection( enviro )
        enviro = enviro.nil? ? nil : enviro.to_sym
        
        shard_collections[ enviro ] ||= ShardCollection.new
      end

      def shard_collections
        @shard_collections ||= {}
      end

  end
  
end