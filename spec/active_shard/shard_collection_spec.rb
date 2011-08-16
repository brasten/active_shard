require 'spec_helper'
require 'active_shard/shard_collection'
require 'active_shard/shard_definition'

module ActiveShard
  describe ShardCollection do
    context "a new instance" do
      let :collection do
        ShardCollection.new
      end

      describe "#add_shard" do
        it "should add shard to collection when provided a ShardDefinition" do
          collection.add_shard( ShardDefinition.new( :one, :schema => :data ) )

          shard = collection.shard( :one )
          shard.should be_kind_of( ShardDefinition )
          shard.schema.should == :data
        end

        it "should add shard to collection when provided :shard_name, {options}" do
          collection.add_shard( :two, :schema => :log )

          shard = collection.shard( :two )
          shard.should be_kind_of( ShardDefinition )
          shard.schema.should == :log
        end
      end
    end

    context "instantiated with five definitions" do
      let :collection do
        ShardCollection.new([
          ShardDefinition.new( :one,    :schema => :data ),
          ShardDefinition.new( :two,    :schema => :data ),
          ShardDefinition.new( :three,  :schema => :log ),
          ShardDefinition.new( :four,   :schema => :log ),
          ShardDefinition.new( :five,   :schema => :log )
        ])
      end

      subject { collection }

      it { should have( 5 ).shard_definitions }

      describe "#by_schema( :data )" do
        subject { collection.by_schema( :data ) }

        it { should be_a( ShardCollection ) }

        it { should have( 2 ).shard_definitions }

        it "should contain shard :one" do
          subject.shard( :one ).should_not be_nil
        end

        it "should contain shard :two" do
          subject.shard( :two ).should_not be_nil
        end
      end

      describe "#remove_shard( :one )" do
        it "should return removed shard" do
          collection.remove_shard( :one ).should be_a( ShardDefinition )
        end

        it "should remove shard from collection" do
          collection.remove_shard( :one )
          collection.should have( 4 ).shard_definitions
        end
      end

      describe "#remove_shard( :blah )" do
        it "should return nil" do
          collection.remove_shard( :blah ).should be_nil
        end

        it "should not remove anything from collection" do
          collection.remove_shard( :blah )
          collection.should have( 5 ).shard_definitions
        end
      end

      describe "#shard_name_exists?" do
        it "should return true if shard exists" do
          collection.shard_name_exists?( :one ).should be_true
        end

        it "should return false if shard does not exist" do
          collection.shard_name_exists?( :blah ).should be_false
        end
      end

    end
  end

end