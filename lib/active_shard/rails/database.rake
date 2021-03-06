namespace :shards do

  desc 'Create the database from config/database.yml for the current Rails.env (use db:create:all to create all dbs in the config)'
  task :create => :environment do

    # Make the test database at the same time as the development one, if it exists
    if Rails.env.development?
      ActiveShard.config.shard_definitions( :test ).each do |definition|
        create_database(definition)
      end
    end
    ActiveShard.config.shard_definitions( Rails.env.to_sym ).each do |definition|
      create_database( definition )
    end
  end

  def create_database( definition )
    begin
      if definition.connection_adapter =~ /sqlite/
        active_shard_does_not_implement!( definition.connection_adapter )
      else
        pool = ActiveShard::ActiveRecord::ConnectionProxyPool.new( definition )
        pool.connection
      end
    rescue
      case definition.connection_adapter
      when /mysql/
        @charset   = ENV['CHARSET']   || 'utf8'
        @collation = ENV['COLLATION'] || 'utf8_unicode_ci'
        creation_options = {:charset => (definition.connection_spec['charset'] || @charset), :collation => (definition.connection_spec['collation'] || @collation)}
        error_class = definition.connection_adapter =~ /mysql2/ ? Mysql2::Error : Mysql::Error
        access_denied_error = 1045
        begin
          sd = ActiveShard::ShardDefinition.new(
            definition.name, { :schema => definition.schema }.merge( definition.connection_spec ).merge( :database => nil )
          )

          pool = ActiveShard::ActiveRecord::ConnectionProxyPool.new( sd )

          pool.connection.create_database( definition.connection_database, creation_options )

          ActiveShard::ActiveRecord::ConnectionProxyPool.new( definition ).connection
        rescue error_class => sqlerr
          $stderr.puts sqlerr.error
          $stderr.puts "Couldn't create database for #{definition.inspect}"
        end
      when 'postgresql'
        active_shard_does_not_implement!( 'postgresql' )
      end
    else
      $stderr.puts "#{definition.connection_database} already exists"
    end
  end

  desc "Migrate the database (options: VERSION=x, VERBOSE=false)."
  task :migrate, [:shard_name] => :environment do |t, args|
    schemas = {}

    active_shard_definitions( args ).each do |shard_definition|
      with_shard( shard_definition.name ) do |shard_name, schema|
        schemas[schema] = shard_name

        ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
        ActiveRecord::Migrator.migrate("db/migrate/#{schema}/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
      end
    end

    schemas.each_pair { |schema, shard| dump_schema( shard ) }
  end

  namespace :migrate do
    # desc  'Rollbacks the database one migration and re migrate up (options: STEP=x, VERSION=x).'
    task :redo, [:shard_name] => :environment do |t, args|
      if ENV["VERSION"]
        Rake::Task["shards:migrate:down"].invoke( *args.values )
        Rake::Task["shards:migrate:up"].invoke( *args.values )
      else
        Rake::Task["shards:rollback"].invoke( *args.values )
        Rake::Task["shards:migrate"].invoke( *args.values )
      end
    end

    # desc 'Runs the "up" for a given migration VERSION.'
    task :up, [:shard_name] => :environment do |t, args|
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version

      with_shard( args ) do |shard_name, schema|
        ActiveRecord::Migrator.run(:up, "db/migrate/#{schema}", version)

        dump_schema( shard_name )
      end
    end

    # desc 'Runs the "down" for a given migration VERSION.'
    task :down, [:shard_name] => :environment do |t, args|
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version

      with_shard( args ) do |shard_name, schema|
        ActiveRecord::Migrator.run(:down, "db/migrate/#{schema}", version)

        dump_schema( shard_name )
      end
    end
  end

  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
  task :rollback, [:shard_name] => :environment do |t, args|
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1

    with_shard( args ) do |shard_name, schema|
      ActiveRecord::Migrator.rollback("db/migrate/#{schema}", step)

      dump_schema( shard_name )
    end
  end

  # desc 'Pushes the schema to the next version (specify steps w/ STEP=n).'
  task :forward, [:shard_name] => :environment do |t, args|
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1

    with_shard( args ) do |shard_name, schema|
      ActiveRecord::Migrator.forward("db/migrate/#{schema}", step)

      dump_schema( shard_name )
    end
  end

  desc "Retrieves the current schema version number"
  task :version, [:shard_name] => :environment do |t, args|
    with_shard( args ) do |shard_name, schema|
      puts "Current version: #{ActiveRecord::Migrator.current_version}"
    end
  end

  namespace :schema do

    desc "Create a db/<schema>_schema.rb file that can be portably used against any DB supported by AR"
    task :dump, [:shard_name] => :environment do |t, args|
      require 'active_record/schema_dumper'

      defs = active_shard_definitions( args )

      defs.schemas.each do |schema|
        shard_definition = defs.by_schema( schema ).first

        with_shard( shard_definition.name ) do
          File.open( "#{Rails.root}/db/#{schema}_schema.rb", "w" ) do |file|
            ActiveRecord::SchemaDumper.dump( ActiveRecord::Base.connection, file )
          end
        end
      end

      Rake::Task["shards:schema:dump"].reenable
    end

    desc "Load a <schema>_schema.rb file into the database"
    task :load, [:shard_name] => :environment do |t, args|
      defs = active_shard_definitions( args )

      defs.each do |shard_definition|
        with_shard( shard_definition.name ) do
          ActiveRecord::Schema.class_eval <<-EOM
            def self.migrations_path
              "db/migrate/#{shard_definition.schema}"
            end
          EOM

          file = "#{Rails.root}/db/#{shard_definition.schema}_schema.rb"
          if File.exists?( file )
            load( file )
          else
            abort %{#{file} doesn't exist yet. Run "rake shards:migrate[#{shard_definition.name}]" to create it then try again. If you do not intend to use a database, you should instead alter #{Rails.root}/config/application.rb to limit the frameworks that will be loaded}
          end
        end
      end
    end
  end

  namespace :structure do
    desc "Dump the database structure to an SQL file"
    task :dump, [:shard_name] => :environment do |t, args|
      ActiveShard.with_environment( :development ) do
        defs = active_shard_definitions( args )

        defs.schemas.each do |schema|
          shard_definition = defs.by_schema( schema ).first

          with_shard( shard_definition.name ) do

            structure_file_path = "#{Rails.root}/db/#{schema}_structure.sql"

            abcs = ActiveShard.shard( shard_definition.name ).connection_adapter
            case abcs
            when /mysql/, "oci", "oracle"
              # We are already connected via with_shard, so just use.
              #
              File.open( structure_file_path, "w+" ) { |f| f << ActiveRecord::Base.connection.structure_dump }
            when "postgresql", "sqlite", "sqlite3", "sqlserver", "firebird"
              active_shard_does_not_implement!(abcs)
            else
              raise "Task not supported by '#{abcs}'"
            end

            if ActiveRecord::Base.connection.supports_migrations?
              File.open( structure_file_path, "a" ) { |f| f << ActiveRecord::Base.connection.dump_schema_information }
            end
          end
        end
      end
    end
  end

  namespace :test do
    # desc "Recreate the test database from the current schema.rb"
    task :load => 'shards:test:purge' do
      ActiveShard.with_environment( :test ) do
        ActiveRecord::Schema.verbose = false

        puts "Building test shards ..."
        ActiveShard.shard_definitions.each do |shard_definition|
          puts "  --> #{shard_definition.name} (#{shard_definition.schema})"
          Rake::Task["shards:schema:load"].invoke( shard_definition.name )
          Rake::Task["shards:schema:load"].reenable
        end
      end
    end

    # desc "Recreate the test database from the current environment's database schema"
    task :clone => %w(shards:schema:dump shards:test:load)

    # desc "Recreate the test databases from the development structure"
    task :clone_structure, [:shard_name] => [ "shards:structure:dump", "shards:test:purge" ] do |t, args|
      ActiveShard.with_environment( :test ) do
        defs = active_shard_definitions( args )

        defs.each do |shard_definition|
          adapter = shard_definition.connection_adapter

          case adapter
          when /mysql/
            with_shard( shard_definition.name ) do
              ActiveRecord::Base.connection.execute('SET foreign_key_checks = 0')
              IO.readlines("#{Rails.root}/db/#{shard_definition.schema}_structure.sql").join.split("\n\n").each do |table|
                ActiveRecord::Base.connection.execute(table)
              end
            end
          when "postgresql", "sqlite", "sqlite3", "sqlserver", "oci", "oracle", "firebird"
            active_shard_does_not_implement!( adapter )
          else
            raise "Task not supported by '#{adapter}'"
          end
        end
      end
    end

    # desc "Empty the test database"
    task :purge => :environment do
      ActiveShard.with_environment( :test ) do
        ActiveShard.shard_definitions.each do |shard_definition|
          with_shard( shard_definition.name ) do |shard_name, schema|
            adapter = ActiveShard.shard( shard_name ).connection_adapter

            case adapter
            when /mysql/
              ActiveRecord::Base.connection.recreate_database(
                shard_definition.connection_database,
                shard_definition.connection_spec
              )
            when "postgresql", "sqlite", "sqlite3", "sqlserver", "oci", "oracle", "firebird"
              active_shard_does_not_implement!( adapter )
            else
              raise "Task not supported by '#{abcs["test"]["adapter"]}'"
            end
          end
        end
      end
    end

    # desc 'Check for pending migrations and load the test schema'
    task :prepare => :environment do
      clone_schema
    end
  end
end

def dump_schema( *args )
  Rake::Task[{ :sql  => "shards:structure:dump", :ruby => "shards:schema:dump" }[ActiveRecord::Base.schema_format]].invoke(*args)
end

def clone_schema( *args )
  Rake::Task[{ :sql  => "shards:test:clone_structure", :ruby => "shards:test:load" }[ActiveRecord::Base.schema_format]].invoke(*args)
end

def active_shard_does_not_implement!( adapter )
  raise "Unimplemented by ActiveShard at the moment. If someone using #{adapter} wants to fix this, that would be awesome!"
end

def active_shard_definitions( options={} )
  shard_name = options[ :shard_name ]

  if shard_name.blank?
    ActiveShard.shard_definitions
  else
    ActiveShard::ShardCollection.new([ ActiveShard.shard( shard_name ) ])
  end
end

def with_shard( args )
  shard_name =
    case args
    when Symbol, String
      args.to_sym
    else
      args[ :shard_name ].nil? ? nil : args[ :shard_name ].to_sym
    end

  raise "No shard specified. Please run with shard name, rake task[shard_name]" unless shard_name
  
  schema      = ActiveShard.shard( shard_name ).schema.to_sym

  ActiveRecord::Base.send( :include, ActiveShard::ActiveRecord::ShardSupport )
  ActiveRecord::Base.schema_name( schema )

  ActiveShard.with( shard_name ) do
    yield( shard_name, schema )
  end
end