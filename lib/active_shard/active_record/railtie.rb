require "active_shard"
require "rails"

module ActiveShard
  # = Active Record Railtie
  class Railtie < Rails::Railtie

    rake_tasks do
      load "active_shard/active_record/rails/database.rake"
    end

  end
end
