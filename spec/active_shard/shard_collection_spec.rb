require 'spec_helper'
require 'active_shard/shard_collection'
require 'active_shard/shard_definition'

describe ActiveShard::ShardCollection do

  describe "#add_shard" do
    context "using ShardDefinitions" do
      before do
        @collection = ActiveShard::ShardCollection.new
        @collection.add_shard( ActiveShard::ShardDefinition.new( :one, :schema => :data ) )
        @collection.add_shard( ActiveShard::ShardDefinition.new( :two, :schema => :log ) )
        @collection.add_shard( ActiveShard::ShardDefinition.new( :three, :schema => :log ) )
      end

      it "should add shards to collection" do
        shard = @collection.shard( :one )
        shard.should be_kind_of( ActiveShard::ShardDefinition )
        shard.schema.should == :data

        shard = @collection.shard( :two )
        shard.should be_kind_of( ActiveShard::ShardDefinition )
        shard.schema.should == :log

        shard = @collection.shard( :three )
        shard.should be_kind_of( ActiveShard::ShardDefinition )
        shard.schema.should == :log
      end
    end

    context "using add_shard params" do
      before do
        @collection = ActiveShard::ShardCollection.new
        @collection.add_shard( :one,    :schema => :data )
        @collection.add_shard( :two,    :schema => :log )
        @collection.add_shard( :three,  :schema => :log )
      end

      it "should add shards to collection" do
        shard = @collection.shard( :one )
        shard.should be_kind_of( ActiveShard::ShardDefinition )
        shard.schema.should == :data

        shard = @collection.shard( :two )
        shard.should be_kind_of( ActiveShard::ShardDefinition )
        shard.schema.should == :log

        shard = @collection.shard( :three )
        shard.should be_kind_of( ActiveShard::ShardDefinition )
        shard.schema.should == :log
      end
    end

  end

end