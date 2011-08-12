require "active_shard"
require "rails"

module ActiveShard
  module ActiveRecord
    class Railtie < Rails::Railtie

      config.active_shard = ActiveSupport::OrderedOptions.new

      rake_tasks do
        load "active_shard/active_record/rails/database.rake"
      end

      initializer "active_shard.logger" do
        ActiveSupport.on_load(:active_shard) { self.logger ||= ::Rails.logger }
      end

      initializer "active_shard.set_configs" do |app|
        ActiveSupport.on_load(:active_record) do
          app.config.active_record.each do |k,v|
            send "#{k}=", v
          end
        end
      end

      initializer "active_shard.initialize_database" do |app|
        ActiveSupport.on_load(:active_record) do
          self.configurations = app.config.database_configuration
          establish_connection
        end
      end

  ActiveShard.config do |c|
    definitions = ActiveShard::ShardDefinition.from_yaml_file( File.expand_path( '../shards.yml', __FILE__ ) )

    definitions[ Rails.env.to_sym ].each do |shard|
      c.add_shard( shard )
    end
  end

  require 'active_shard/active_record'

  ActiveRecord::Base.send( :include, ActiveShard::ActiveRecord::ShardSupport )

  ActiveRecord::Base.connection_handler =
    ActiveShard::ActiveRecord::ConnectionHandler.new(
      ActiveShard.config.shard_definitions,
      :shard_lookup => ActiveShard::ShardLookupHandler.new( :scope => ActiveShard.scope, :config => ActiveShard.config )
    )

  ActiveRecord::Base.schema_name( :main )


    end
  end
end
