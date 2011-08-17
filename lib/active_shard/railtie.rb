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
        ActiveSupport.on_load(:active_shard) do
          app.config.active_shard.each do |k,v|
            send "#{k}=", v
          end
        end
      end

      initializer "active_shard.initialize_framework" do |app|
        ActiveSupport.on_load(:active_shard) do
          require 'active_shard/active_record'

          ActiveRecord::Base.send( :include, ActiveShard::ActiveRecord::ShardSupport )

          handler =
            ActiveShard::ActiveRecord::ConnectionHandler.new(
               :shard_lookup => ActiveShard::ShardLookupHandler.new( :scope => ActiveShard.scope )
             )

          self.shard_observers << handler

          ActiveRecord::Base.connection_handler = handler
        end
      end

      initializer "active_shard.initialize_shard_configuration" do |app|
        ActiveSupport.on_load(:active_shard) do
          unless app.config.active_shard.shard_configuration
            self.shard_configuration =
              ActiveShard::ShardDefinition.from_yaml_file( Rails.root.join( 'config', 'shards.yml' ) )
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
end
