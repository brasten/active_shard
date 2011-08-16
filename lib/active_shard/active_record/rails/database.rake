namespace :shards do
  desc "Migrate the database (options: VERSION=x, VERBOSE=false)."
  task :migrate, [:shard_name] => :environment do |t, args|
    shard_name  = args[:shard_name].to_sym
    schema      = ActiveShard.config.shard( shard_name ).schema.to_sym

    ActiveRecord::Base.send( :include, ActiveShard::ActiveRecord::ShardSupport )
    ActiveRecord::Base.schema_name( schema )

    ActiveShard.with( shard_name ) do
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

      shard_name  = args[:shard_name].to_sym
      schema      = ActiveShard.config.shard( shard_name ).schema.to_sym

      ActiveRecord::Base.send( :include, ActiveShard::ActiveRecord::ShardSupport )
      ActiveRecord::Base.schema_name( schema )

      ActiveShard.with( shard_name ) do
        ActiveRecord::Migrator.run(:up, "db/migrate/#{schema}", version)
        Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
      end
    end

    # desc 'Runs the "down" for a given migration VERSION.'
    task :down, [:shard_name] => :environment do |t, args|
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version

      shard_name  = args[:shard_name].to_sym
      schema      = ActiveShard.config.shard( shard_name ).schema.to_sym

      ActiveRecord::Base.send( :include, ActiveShard::ActiveRecord::ShardSupport )
      ActiveRecord::Base.schema_name( schema )

      ActiveShard.with( shard_name ) do
        ActiveRecord::Migrator.run(:down, "db/migrate/#{schema}", version)
        Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
      end
    end

  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
  task :rollback, [:shard_name] => :environment do |t, args|
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1

    shard_name  = args[:shard_name].to_sym
    schema      = ActiveShard.config.shard( shard_name ).schema.to_sym

    ActiveRecord::Base.send( :include, ActiveShard::ActiveRecord::ShardSupport )
    ActiveRecord::Base.schema_name( schema )

    ActiveShard.with( shard_name ) do
      ActiveRecord::Migrator.rollback('db/migrate/', step)
      Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end
  end

  # desc 'Pushes the schema to the next version (specify steps w/ STEP=n).'
  task :forward, [:shard_name] => :environment do |t, args|
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1

    shard_name  = args[:shard_name].to_sym
    schema      = ActiveShard.config.shard( shard_name ).schema.to_sym

    ActiveRecord::Base.send( :include, ActiveShard::ActiveRecord::ShardSupport )
    ActiveRecord::Base.schema_name( schema )

    ActiveShard.with( shard_name ) do
      ActiveRecord::Migrator.forward('db/migrate/', step)
      Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end
  end

  desc "Retrieves the current schema version number"
  task :version => :environment do
    puts "Current version: #{ActiveRecord::Migrator.current_version}"
  end
#
#  # desc "Raises an error if there are pending migrations"
#  task :abort_if_pending_migrations => :environment do
#    if defined? ActiveRecord
#      pending_migrations = ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations
#
#      if pending_migrations.any?
#        puts "You have #{pending_migrations.size} pending migrations:"
#        pending_migrations.each do |pending_migration|
#          puts '  %4d %s' % [pending_migration.version, pending_migration.name]
#        end
#        abort %{Run "rake db:migrate" to update your database then try again.}
#      end
#    end
#  end
#
#  desc 'Create the database, load the schema, and initialize with the seed data (use db:reset to also drop the db first)'
#  task :setup => [ 'db:create', 'db:schema:load', 'db:seed' ]
#
#  desc 'Load the seed data from db/seeds.rb'
#  task :seed => 'db:abort_if_pending_migrations' do
#    seed_file = File.join(Rails.root, 'db', 'seeds.rb')
#    load(seed_file) if File.exist?(seed_file)
#  end
#
#  namespace :fixtures do
#    desc "Load fixtures into the current environment's database.  Load specific fixtures using FIXTURES=x,y. Load from subdirectory in test/fixtures using FIXTURES_DIR=z. Specify an alternative path (eg. spec/fixtures) using FIXTURES_PATH=spec/fixtures."
#    task :load => :environment do
#      require 'active_record/fixtures'
#
#      ActiveRecord::Base.establish_connection(Rails.env)
#      base_dir = ENV['FIXTURES_PATH'] ? File.join(Rails.root, ENV['FIXTURES_PATH']) : File.join(Rails.root, 'test', 'fixtures')
#      fixtures_dir = ENV['FIXTURES_DIR'] ? File.join(base_dir, ENV['FIXTURES_DIR']) : base_dir
#
#      (ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/).map {|f| File.join(fixtures_dir, f) } : Dir["#{fixtures_dir}/**/*.{yml,csv}"]).each do |fixture_file|
#        Fixtures.create_fixtures(fixtures_dir, fixture_file[(fixtures_dir.size + 1)..-5])
#      end
#    end
#
#    # desc "Search for a fixture given a LABEL or ID. Specify an alternative path (eg. spec/fixtures) using FIXTURES_PATH=spec/fixtures."
#    task :identify => :environment do
#      require 'active_record/fixtures'
#
#      label, id = ENV["LABEL"], ENV["ID"]
#      raise "LABEL or ID required" if label.blank? && id.blank?
#
#      puts %Q(The fixture ID for "#{label}" is #{Fixtures.identify(label)}.) if label
#
#      base_dir = ENV['FIXTURES_PATH'] ? File.join(Rails.root, ENV['FIXTURES_PATH']) : File.join(Rails.root, 'test', 'fixtures')
#      Dir["#{base_dir}/**/*.yml"].each do |file|
#        if data = YAML::load(ERB.new(IO.read(file)).result)
#          data.keys.each do |key|
#            key_id = Fixtures.identify(key)
#
#            if key == label || key_id == id.to_i
#              puts "#{file}: #{key} (#{key_id})"
#            end
#          end
#        end
#      end
#    end
#  end
#
#  namespace :schema do
#    desc "Create a db/schema.rb file that can be portably used against any DB supported by AR"
#    task :dump => :environment do
#      require 'active_record/schema_dumper'
#      File.open(ENV['SCHEMA'] || "#{Rails.root}/db/schema.rb", "w") do |file|
#        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
#      end
#      Rake::Task["db:schema:dump"].reenable
#    end
#
#    desc "Load a schema.rb file into the database"
#    task :load => :environment do
#      file = ENV['SCHEMA'] || "#{Rails.root}/db/schema.rb"
#      if File.exists?(file)
#        load(file)
#      else
#        abort %{#{file} doesn't exist yet. Run "rake db:migrate" to create it then try again. If you do not intend to use a database, you should instead alter #{Rails.root}/config/application.rb to limit the frameworks that will be loaded}
#      end
#    end
#  end
#
#  namespace :structure do
#    desc "Dump the database structure to an SQL file"
#    task :dump => :environment do
#      abcs = ActiveRecord::Base.configurations
#      case abcs[Rails.env]["adapter"]
#      when /mysql/, "oci", "oracle"
#        ActiveRecord::Base.establish_connection(abcs[Rails.env])
#        File.open("#{Rails.root}/db/#{Rails.env}_structure.sql", "w+") { |f| f << ActiveRecord::Base.connection.structure_dump }
#      when "postgresql"
#        ENV['PGHOST']     = abcs[Rails.env]["host"] if abcs[Rails.env]["host"]
#        ENV['PGPORT']     = abcs[Rails.env]["port"].to_s if abcs[Rails.env]["port"]
#        ENV['PGPASSWORD'] = abcs[Rails.env]["password"].to_s if abcs[Rails.env]["password"]
#        search_path = abcs[Rails.env]["schema_search_path"]
#        unless search_path.blank?
#          search_path = search_path.split(",").map{|search_path| "--schema=#{search_path.strip}" }.join(" ")
#        end
#        `pg_dump -i -U "#{abcs[Rails.env]["username"]}" -s -x -O -f db/#{Rails.env}_structure.sql #{search_path} #{abcs[Rails.env]["database"]}`
#        raise "Error dumping database" if $?.exitstatus == 1
#      when "sqlite", "sqlite3"
#        dbfile = abcs[Rails.env]["database"] || abcs[Rails.env]["dbfile"]
#        `#{abcs[Rails.env]["adapter"]} #{dbfile} .schema > db/#{Rails.env}_structure.sql`
#      when "sqlserver"
#        `scptxfr /s #{abcs[Rails.env]["host"]} /d #{abcs[Rails.env]["database"]} /I /f db\\#{Rails.env}_structure.sql /q /A /r`
#        `scptxfr /s #{abcs[Rails.env]["host"]} /d #{abcs[Rails.env]["database"]} /I /F db\ /q /A /r`
#      when "firebird"
#        set_firebird_env(abcs[Rails.env])
#        db_string = firebird_db_string(abcs[Rails.env])
#        sh "isql -a #{db_string} > #{Rails.root}/db/#{Rails.env}_structure.sql"
#      else
#        raise "Task not supported by '#{abcs[Rails.env]["adapter"]}'"
#      end
#
#      if ActiveRecord::Base.connection.supports_migrations?
#        File.open("#{Rails.root}/db/#{Rails.env}_structure.sql", "a") { |f| f << ActiveRecord::Base.connection.dump_schema_information }
#      end
#    end
#  end
#
#  namespace :test do
#    # desc "Recreate the test database from the current schema.rb"
#    task :load => 'db:test:purge' do
#      ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])
#      ActiveRecord::Schema.verbose = false
#      Rake::Task["db:schema:load"].invoke
#    end
#
#    # desc "Recreate the test database from the current environment's database schema"
#    task :clone => %w(db:schema:dump db:test:load)
#
#    # desc "Recreate the test databases from the development structure"
#    task :clone_structure => [ "db:structure:dump", "db:test:purge" ] do
#      abcs = ActiveRecord::Base.configurations
#      case abcs["test"]["adapter"]
#      when /mysql/
#        ActiveRecord::Base.establish_connection(:test)
#        ActiveRecord::Base.connection.execute('SET foreign_key_checks = 0')
#        IO.readlines("#{Rails.root}/db/#{Rails.env}_structure.sql").join.split("\n\n").each do |table|
#          ActiveRecord::Base.connection.execute(table)
#        end
#      when "postgresql"
#        ENV['PGHOST']     = abcs["test"]["host"] if abcs["test"]["host"]
#        ENV['PGPORT']     = abcs["test"]["port"].to_s if abcs["test"]["port"]
#        ENV['PGPASSWORD'] = abcs["test"]["password"].to_s if abcs["test"]["password"]
#        `psql -U "#{abcs["test"]["username"]}" -f #{Rails.root}/db/#{Rails.env}_structure.sql #{abcs["test"]["database"]}`
#      when "sqlite", "sqlite3"
#        dbfile = abcs["test"]["database"] || abcs["test"]["dbfile"]
#        `#{abcs["test"]["adapter"]} #{dbfile} < #{Rails.root}/db/#{Rails.env}_structure.sql`
#      when "sqlserver"
#        `osql -E -S #{abcs["test"]["host"]} -d #{abcs["test"]["database"]} -i db\\#{Rails.env}_structure.sql`
#      when "oci", "oracle"
#        ActiveRecord::Base.establish_connection(:test)
#        IO.readlines("#{Rails.root}/db/#{Rails.env}_structure.sql").join.split(";\n\n").each do |ddl|
#          ActiveRecord::Base.connection.execute(ddl)
#        end
#      when "firebird"
#        set_firebird_env(abcs["test"])
#        db_string = firebird_db_string(abcs["test"])
#        sh "isql -i #{Rails.root}/db/#{Rails.env}_structure.sql #{db_string}"
#      else
#        raise "Task not supported by '#{abcs["test"]["adapter"]}'"
#      end
#    end
#
#    # desc "Empty the test database"
#    task :purge => :environment do
#      abcs = ActiveRecord::Base.configurations
#      case abcs["test"]["adapter"]
#      when /mysql/
#        ActiveRecord::Base.establish_connection(:test)
#        ActiveRecord::Base.connection.recreate_database(abcs["test"]["database"], abcs["test"])
#      when "postgresql"
#        ActiveRecord::Base.clear_active_connections!
#        drop_database(abcs['test'])
#        create_database(abcs['test'])
#      when "sqlite","sqlite3"
#        dbfile = abcs["test"]["database"] || abcs["test"]["dbfile"]
#        File.delete(dbfile) if File.exist?(dbfile)
#      when "sqlserver"
#        dropfkscript = "#{abcs["test"]["host"]}.#{abcs["test"]["database"]}.DP1".gsub(/\\/,'-')
#        `osql -E -S #{abcs["test"]["host"]} -d #{abcs["test"]["database"]} -i db\\#{dropfkscript}`
#        `osql -E -S #{abcs["test"]["host"]} -d #{abcs["test"]["database"]} -i db\\#{Rails.env}_structure.sql`
#      when "oci", "oracle"
#        ActiveRecord::Base.establish_connection(:test)
#        ActiveRecord::Base.connection.structure_drop.split(";\n\n").each do |ddl|
#          ActiveRecord::Base.connection.execute(ddl)
#        end
#      when "firebird"
#        ActiveRecord::Base.establish_connection(:test)
#        ActiveRecord::Base.connection.recreate_database!
#      else
#        raise "Task not supported by '#{abcs["test"]["adapter"]}'"
#      end
#    end
#
#    # desc 'Check for pending migrations and load the test schema'
#    task :prepare => 'db:abort_if_pending_migrations' do
#      if defined?(ActiveRecord) && !ActiveRecord::Base.configurations.blank?
#        Rake::Task[{ :sql  => "db:test:clone_structure", :ruby => "db:test:load" }[ActiveRecord::Base.schema_format]].invoke
#      end
#    end
#  end
#
#  namespace :sessions do
#    # desc "Creates a sessions migration for use with ActiveRecord::SessionStore"
#    task :create => :environment do
#      raise "Task unavailable to this database (no migration support)" unless ActiveRecord::Base.connection.supports_migrations?
#      require 'rails/generators'
#      Rails::Generators.configure!
#      require 'rails/generators/rails/session_migration/session_migration_generator'
#      Rails::Generators::SessionMigrationGenerator.start [ ENV["MIGRATION"] || "add_sessions_table" ]
#    end
#
#    # desc "Clear the sessions table"
#    task :clear => :environment do
#      ActiveRecord::Base.connection.execute "DELETE FROM #{session_table_name}"
#    end
  end
end
#
#task 'test:prepare' => 'db:test:prepare'
#
#def drop_database(config)
#  case config['adapter']
#  when /mysql/
#    ActiveRecord::Base.establish_connection(config)
#    ActiveRecord::Base.connection.drop_database config['database']
#  when /^sqlite/
#    require 'pathname'
#    path = Pathname.new(config['database'])
#    file = path.absolute? ? path.to_s : File.join(Rails.root, path)
#
#    FileUtils.rm(file)
#  when 'postgresql'
#    ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
#    ActiveRecord::Base.connection.drop_database config['database']
#  end
#end
#
#def session_table_name
#  ActiveRecord::SessionStore::Session.table_name
#end
#
#def set_firebird_env(config)
#  ENV["ISC_USER"]     = config["username"].to_s if config["username"]
#  ENV["ISC_PASSWORD"] = config["password"].to_s if config["password"]
#end
#
#def firebird_db_string(config)
#  FireRuby::Database.db_string_for(config.symbolize_keys)
#end
