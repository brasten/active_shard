require 'spec_helper'
require 'active_shard/config'
require 'active_shard/shard_definition'

module ActiveShard

  describe Config do

    context "with four shards" do
      before do
        @config = Config.new
        @config.add_shard( :test, ShardDefinition.new( :db1, :schema => 'data', :host => 'host1' ) )
        @config.add_shard( :test, ShardDefinition.new( :db2, :schema => 'data', :host => 'host2' ) )
        @config.add_shard( :test, ShardDefinition.new( :db3, :schema => 'data', :host => 'host3' ) )
        @config.add_shard( :test, ShardDefinition.new( :directory, :schema => 'directory', :host => 'host4' ) )
      end

      it "should have 4 shards" do
        @config.should have(4).shard_definitions( :test )
      end

      describe "#add_shard( :test, ... )" do
        before do
          @config.add_shard( :test, ShardDefinition.new( :db4, :schema => 'data', :host => 'host4' ) )
        end

        it "should add one shard definition to test environment" do
          @config.should have(5).shard_definitions( :test )
        end
      end

      describe "#add_shard( :blah, ... )" do
        before do
          @config.add_shard( :blah, ShardDefinition.new( :db4, :schema => 'data', :host => 'host4' ) )
        end

        it "should add one shard definition to blah environment" do
          @config.should have(1).shard_definitions( :blah )
        end

        it "should still have 4 shard defintions in test environment" do
          @config.should have(4).shard_definitions( :test )
        end
      end

      describe "#shard( :test, shard_name )" do
        before do
          @shard = @config.shard( :test, :db3 )
        end

        it "should return proper shard" do
          @shard.name.should == :db3
          @shard.connection_spec[:host].should == 'host3'
        end
      end

      describe "#shard( :blah, shard_name )" do
        before do
          @shard = @config.shard( :blah, :db3 )
        end

        it "should return nil" do
          @shard.should be_nil
        end
      end

    end
  end

end