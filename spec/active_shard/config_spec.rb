require 'spec_helper'
require 'active_shard/config'

describe ActiveShard::Config do

  context "with four shards" do
    before do
      @config = ActiveShard::Config.new
      @config.add_shard( :db1, :schema => 'data', :host => 'host1' )
      @config.add_shard( :db2, :schema => 'data', :host => 'host2' )
      @config.add_shard( :db3, :schema => 'data', :host => 'host3' )
      @config.add_shard( :directory, :schema => 'directory', :host => 'host4' )
    end

    it "should have 4 shards" do
      @config.should have(4).shard_definitions
    end

    describe "#add_shard( ... )" do
       before do
         @config.add_shard( :db4, :schema => 'data', :host => 'host4' )
       end

      it "should add one shard definition" do
        @config.should have(5).shard_definitions
      end
    end

    describe "#shard( shard_name )" do
      before do
        @shard = @config.shard( :db3 )
      end

      it "should return proper shard" do
        @shard.name.should == :db3
        @shard.connection_spec[:host].should == 'host3'
      end
    end

  end
end