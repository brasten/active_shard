ActiveShard - Multi-schema sharding for ActiveRecord
====================================================

ActiveShard is a library built primarily for sharding in ActiveRecord. It also supports multiple databases with differing schemas. As with the other sharding libraries for ActiveRecord (there are a few), this library represents the best solution to the authors' sharding needs. If you've been unhappy with other options, ActiveShard might be for you.


## CAVEATS ##

### Railtie isn't finished ... ###

... so there are some additional steps you'll need to take to get this working. Specifically:

Add the following to the end of your config/application.rb:

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
    
Once we complete the ActiveShard Railtie, these lines will not be necessary.


### Where are the specs? ###

Good eye. This library is being extracted from an existing project where application-specific tests were written to test the sharding functionality.

Generic and more detailed specs are being written and will be added shortly.


## Design goals ##

The fundamental purpose of ActiveShard is to provide a framework that allows ActiveRecord to connect to multiple databases with multiple different schemas. All other features are a subset of this framework (sharding, replication, etc).

### More framework, less magic ###

ActiveShard doesn't do much guessing or sleight of hand. Queries are executed against whatever shard is marked as active for the schema used. Instances of models do not remember what shards they belong to.

    ActiveShard.with( :main => :db1 ) do
      user = User.find( 100 )
    end
    
    # this will fail, as no shard is selected at this point -->
    user.save!

This is an intentional design decision. Other libraries go to great lengths to provide smarter implementations, but do so at the expense of flexibility.

In contrast to other implementations, ActiveShard does not reopen or monkey-patch any Rails or ActiveRecord classes. It has been the authors' experience that any Rails application large enough to need sharding probably contains a fair amount of customization already. Sharding libraries which hack up core Rails classes often do not play nice with existing code. ActiveShard (hopefully!) does.


## Install ##

### Rails 3.x ###

Add this line to your Gemfile:

    gem 'active_shard'

Install bundle:

    $ bundle install
    
Add to config/application.rb, right under "require 'rails/all'":

    require 'active_shard/active_record/railtie'


## Most common usage ##

### config/shards.yml (if used in Rails) ###

Create a config/shards.yml file with your desired database configuration. Shards.yml contains the following structure (pseudo-code):

    <environment>
      <schema_name>
        <shard_name>
          <shard_specification>
        <shard_name>
          <shard_specification>
      <schema_name>
        <shard_name>
          <shard_specification>
          
Example shards.yml:

    production:
      directories:
        directory:
          adapter: mysql2
          database: dir_db
          host: localhost
          username: root

      main:
        db1:
          adapter: mysql2
          host: localhost
          database: db1_db
          username: root

        db2:
          adapter: mysql2
          host: localhost
          database: db2_db
          username: root

        db3:
          adapter: mysql2
          host: localhost
          database: db3_db
          username: root

    development:
      directories:
        directory:
          adapter: mysql2
          host: localhost
          database: dir_db_development
          username: root

      main:
        db1:
          adapter: mysql2
          host: localhost
          database: db1_db_development
          username: root


### Schema name for models ###

ActiveRecord models must have a schema name associated with them. Given the shards.yml file specified above, you might see the following models:

    # contains user lookup fields and the shard name on which user's primary data resides
    class UserShard < ActiveRecord::Base
      schema_name :directories
      
      # ...
    end
    
    # primary user data
    class User < ActiveRecord::Base
      schema_name :main
      
      # ...
    end


### Selecting the active shard(s) ###

In order to use a model -- such as the ones specified above -- a shard must be selected as the current active shard *for each schema used.* The easiest way to do this is to pass a block containing the queries to the ActiveShard.with( ... ) method, specifying the active shards in the parameters.

Nested blocks maintain active shard settings for any schemas they do not explicitly set.  Example:

    ActiveShard.with( :directories => :directory ) do
    
      # We can now use the UserShard model as a shard has been 
      # selected for the 'directories' schema.
      #
      user_shard = UserShard.find_by_login( 'xavier' )
      
      # Using the User model here would raise an exception since there
      # is no active shard for the schema that User belongs to ('main').
      #
      # However, if we select a shard for that schema ...
      #
      
      ActiveShard.with( :main => user_shard.shard_name ) do
        
        user = User.find( user_shard.user_id )  # <-- this works.
        
        # ActiveShard effectively 'merges' nested shard selections rather
        # than replace them. The active shards at this point are:
        #
        # :directories  => :directory
        # :main         => <user_shard.shard_name>
        #
        
      end
      
      # ... the active shard for the :main schema has been de-selected,
      # leaving only the :directories => :directory shard as active.
      
    end

To better understand what's happening here, see ActiveShard::Scope.


### Migrations ###

Migrations for each schema must reside in a directory under db/migrate that corresponds to the schema name.

Example:

    db/migrate/main
      20110810103523_create_users_table.rb
    db/migrate/directories
      20110810105318_create_user_shards_table.rb


You can run migrations against a shard by passing the *shard name* into the shards:migrate rake task, like so:

    $ rake shards:migrate[db1]
    
The schema is discovered from the ActiveShard configuration and the proper migrations are executed.

Each shard maintains its own schema_migrations table and can be (must be) migrated independently. This allows you to spin up additional shards in the future by simply adding an entry to your ActiveShard configuration and running migrations against that shard.


### Rails Controllers ###

If you want to send a specified action, or all actions from a controller, to a specific shard,  use this syntax:
  
    class ApplicationController < ActionController::Base
      around_filter :activate_shards
    
      def activate_shards(&block)
        ActiveShard.with( :directories => :directory, :main => :db1 )
      end    
    end


## Other similar libraries ##

There are several, but Octopus (ar-octopus) is the most popular.


## Authors ##

- Brasten Sager ( brasten@dashwire.com )
- Matt Baker ( matt@dashwire.com )

## Copyright

Copyright (c) 2011 Dashwire Inc., released under the MIT license.