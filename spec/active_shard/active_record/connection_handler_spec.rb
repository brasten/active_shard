require 'spec_helper'
require 'active_shard/active_record/connection_handler'

module ActiveShard::ActiveRecord

  describe ConnectionHandler do
    let :shard_definitions do
      yaml = <<-EOY
test:
  schema_one:
    shard_one:
      adapter: sqlite3
      database: spec/output/shard_one.db
    shard_two:
      adapter: sqlite3
      database: spec/output/shard_two.db
  schema_two:
    shard_three:
      adapter: sqlite3
      database: spec/output/shard_three.db
    shard_four:
      adapter: sqlite3
      database: spec/output/shard_four.db
    shard_five:
      adapter: sqlite3
      database: spec/output/shard_five.db
  schema_three:
    shard_six:
      adapter: sqlite3
      database: spec/output/shard_six.db
    shard_seven:
      adapter: sqlite3
      database: spec/output/shard_seven.db
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

        context "with active shards :schema_one => :shard_two, :schema_two => :shard_four" do
          let :lookup_handler do
            handler = mock(:handler)
            handler.stub!(:lookup_active_shard).with(:schema_one).and_return(:shard_two)
            handler.stub!(:lookup_active_shard).with(:schema_two).and_return(:shard_four)
            handler.stub!(:lookup_active_shard).with(:schema_three).and_return(nil)
            handler
          end

          it "should return connection_pool for shard_two when klass.schema_name == :schema_one" do
            pool = handler.retrieve_connection_pool( mock(:klass, :schema_name => :schema_one) )
            pool.spec.config[:adapter].should == 'sqlite3'
            pool.spec.config[:database].should == 'spec/output/shard_two.db'
            pool.should be_instance_of( ::ActiveRecord::ConnectionAdapters::ConnectionPool )
          end

          it "should return connection_pool for shard_four when klass.schema_name == :schema_two" do
            pool = handler.retrieve_connection_pool( mock(:klass, :schema_name => :schema_two) )
            pool.spec.config[:adapter].should == 'sqlite3'
            pool.spec.config[:database].should == 'spec/output/shard_four.db'
            pool.should be_instance_of( ::ActiveRecord::ConnectionAdapters::ConnectionPool )
          end

          it "should return schema_connection_pool for shard_six when klass.schema_name == :schema_three" do
            pool = handler.retrieve_connection_pool( mock(:klass, :schema_name => :schema_three) )
            pool.spec.config[:adapter].should == 'sqlite3'
            pool.spec.config[:database].should == 'spec/output/shard_six.db'
            pool.should be_instance_of( ::ActiveShard::ActiveRecord::SchemaConnectionPool )
          end
        end


      end

    end


  end

end