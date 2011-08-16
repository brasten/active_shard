require 'spec_helper'
require 'active_shard/active_record'
require 'active_record/connection_adapters/sqlite3_adapter'

module ActiveShard::ActiveRecord

  describe ConnectionHandler, :artifacts => true do
    let :shard_definitions do
      yaml = <<-EOY
test:
  schema_one:
    shard_one:
      adapter: sqlite3
      database: #{ARTIFACTS_PATH}/shard_one.db
    shard_two:
      adapter: sqlite3
      database: #{ARTIFACTS_PATH}/shard_two.db
  schema_two:
    shard_three:
      adapter: sqlite3
      database: #{ARTIFACTS_PATH}/shard_three.db
    shard_four:
      adapter: sqlite3
      database: #{ARTIFACTS_PATH}/shard_four.db
    shard_five:
      adapter: sqlite3
      database: #{ARTIFACTS_PATH}/shard_five.db
  schema_three:
    shard_six:
      adapter: sqlite3
      database: #{ARTIFACTS_PATH}/shard_six.db
    shard_seven:
      adapter: sqlite3
      database: #{ARTIFACTS_PATH}/shard_seven.db
EOY
      ActiveShard::ShardDefinition.from_yaml( yaml )[:test]
    end

    describe "#retrieve_connection_pool" do
      context "with schema/shards" do
        let :lookup_handler do
          handler = mock(:handler)
          handler.stub!(:lookup_active_shard).and_return(nil)
          handler
        end

        let :handler do
          ConnectionHandler.new( shard_definitions, :shard_lookup => lookup_handler )
        end

        { :schema_one   => :shard_one,
          :schema_two   => :shard_three,
          :schema_three => :shard_six }.each_pair do |schema_name, shard_name|

          it "should return schema_connection_pool for #{shard_name} when klass.schema_name == :#{schema_name}" do
            pool = handler.retrieve_connection_pool( mock(:klass, :schema_name => schema_name) )
            pool.spec.config[:adapter].should == 'sqlite3'
            pool.spec.config[:database].should == "#{ARTIFACTS_PATH}/#{shard_name}.db"
            pool.should be_instance_of( ActiveShard::ActiveRecord::ConnectionProxyPool )

            pool.connection.should be_instance_of( ActiveShard::ActiveRecord::SchemaConnectionProxy )
          end

        end

        context "with active shards :schema_one => :shard_two, :schema_two => :shard_four", :artifacts => true do
          let :lookup_handler do
            handler = mock(:handler)
            handler.stub!(:lookup_active_shard).with(:schema_one).and_return(:shard_two)
            handler.stub!(:lookup_active_shard).with(:schema_two).and_return(:shard_four)
            handler.stub!(:lookup_active_shard).with(:schema_three).and_return(nil)
            handler
          end

          {
            :schema_one   => [ :shard_two, ::ActiveRecord::ConnectionAdapters::SQLite3Adapter ],
            :schema_two   => [ :shard_four, ::ActiveRecord::ConnectionAdapters::SQLite3Adapter ],
            :schema_three => [ :shard_six, ActiveShard::ActiveRecord::SchemaConnectionProxy ]
          }.each_pair do |schema_name, expectations|
            shard_name = expectations.first
            connection_class = expectations.last

            it "should return connection_pool(#{connection_class}) for #{shard_name} when klass.schema_name == :#{schema_name}" do
              pool = handler.retrieve_connection_pool( mock(:klass, :schema_name => schema_name) )
              pool.spec.config[:adapter].should == 'sqlite3'
              pool.spec.config[:database].should == "#{ARTIFACTS_PATH}/#{shard_name}.db"
              pool.should be_instance_of( ActiveShard::ActiveRecord::ConnectionProxyPool )

              pool.connection.should be_instance_of( connection_class )
            end
          end   # schema_infos
        end   # context
      end   # context
    end   # describe #retrieve_connection_pool
  end   # describe ConnectionHandler

end