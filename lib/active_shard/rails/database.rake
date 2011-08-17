namespace :shards do
  desc "Migrate the database (options: VERSION=x, VERBOSE=false)."
  task :migrate, [:shard_name] => :environment do |t, args|
    with_shard( args ) do
      ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
      ActiveRecord::Migrator.migrate("db/migrate/#{schema}/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
      Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end
  end

  namespace :migrate do
    # desc  'Rollbacks the database one migration and re migrate up (options: STEP=x, VERSION=x).'
    task :redo, [:shard_name] => :environment do |t, args|
      if ENV["VERSION"]
        Rake::Task["db:migrate:down"].invoke(*args.values)
        Rake::Task["db:migrate:up"].invoke(*args.values)
      else
        Rake::Task["db:rollback"].invoke(*args.values)
        Rake::Task["db:migrate"].invoke(*args.values)
      end
    end

    # desc 'Runs the "up" for a given migration VERSION.'
    task :up, [:shard_name] => :environment do |t, args|
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version

      with_shard( args ) do
        ActiveRecord::Migrator.run(:up, "db/migrate/#{schema}", version)
        Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
      end
    end

    # desc 'Runs the "down" for a given migration VERSION.'
    task :down, [:shard_name] => :environment do |t, args|
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version

      with_shard( args ) do
        ActiveRecord::Migrator.run(:down, "db/migrate/#{schema}", version)
        Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
      end
    end
  end

  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
  task :rollback, [:shard_name] => :environment do |t, args|
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1

    with_shard( args ) do
      ActiveRecord::Migrator.rollback('db/migrate/', step)
      Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end
  end

  # desc 'Pushes the schema to the next version (specify steps w/ STEP=n).'
  task :forward, [:shard_name] => :environment do |t, args|
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1

    with_shard( args ) do
      ActiveRecord::Migrator.forward('db/migrate/', step)
      Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end
  end

  desc "Retrieves the current schema version number"
  task :version, [:shard_name] => :environment do |t, args|
    with_shard( args ) do
      puts "Current version: #{ActiveRecord::Migrator.current_version}"
    end
  end

end

def with_shard( args )
  shard_name  = args[ :shard_name ].to_sym
  schema      = ActiveShard.shard( shard_name ).schema.to_sym

  ActiveRecord::Base.send( :include, ActiveShard::ActiveRecord::ShardSupport )
  ActiveRecord::Base.schema_name( schema )

  ActiveShard.with( shard_name ) do
    yield
  end
end