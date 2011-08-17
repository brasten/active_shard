require "active_shard"

module ActiveShard
  class Railtie < Rails::Railtie

    config.active_shard = ActiveSupport::OrderedOptions.new

    rake_tasks do
      load "active_shard/rails/database.rake"
    end

    initializer "active_shard.logger" do
      ActiveSupport.on_load(:active_shard) { self.logger ||= ::Rails.logger }
    end

    initializer "active_shard.set_configs" do |app|
      ActiveSupport.on_load(:active_shard) do
        app.config.active_shard.each do |k,v|
          send "#{k}=", v
        end
      end
    end

    initializer "active_shard.initialize_framework" do |app|
      ActiveSupport.on_load(:active_shard) do

        # TODO: Should anyone build code to plug ActiveShard into other ORMs, this
        # Railtie could support that by respecting a configuration option.
        #
        # something like 'active_shard/data_mapper', 'active_shard/sequel'
        #
        require "active_shard/active_record"

        ::ActiveRecord::Base.send( :include, ActiveShard::ActiveRecord::ShardSupport )
        ::ActiveRecord::Base.schema_name( self.base_schema_name ) if self.base_schema_name

        handler =
          ActiveShard::ActiveRecord::ConnectionHandler.new(
             :shard_lookup => ActiveShard::ShardLookupHandler.new( :scope => ActiveShard.scope )
           )

        self.shard_observers << handler

        ::ActiveRecord::Base.connection_handler = handler
      end
    end

    initializer "active_shard.initialize_shard_configuration" do |app|
      ActiveSupport.on_load(:active_shard) do
        unless app.config.active_shard.shard_configuration
          self.shard_configuration =
            ActiveShard::ShardDefinition.from_yaml_file( Rails.root.join( "config", "shards.yml" ) )
        end
      end
    end

    initializer "active_shard.set_environment" do |app|
      ActiveSupport.on_load(:active_shard) do
        ActiveShard.environment = Rails.env.to_s
      end
    end

  end
end
