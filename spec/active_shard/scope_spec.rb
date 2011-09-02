require 'spec_helper'
require 'active_shard/scope'

module ActiveShard
  
  describe Scope do

    describe "#active_shard_for_schema( schema_name )" do
      context "with scopes: { directory: :directory1, data: db1 }, { data: :db3 }" do
        before do
          @scope = Scope.new
          @scope.push( :directory => :directory1, :data => :db1 )
          @scope.push( :data => :db3 )
        end

        describe "#active_shard_for_schema( schema_name )" do
          it "should return :db3 for :data" do
            @scope.active_shard_for_schema( :data ).should == :db3
          end

          it "should return :directory1 for :directory" do
            @scope.active_shard_for_schema( :directory ).should == :directory1
          end

          it "should return nil for :aux" do
            @scope.active_shard_for_schema( :aux ).should be_nil
          end
        end
      end

      context "with scopes: { directory: :directory1, data: db1 }, { data: :db3 }, :master_shard, { data: :db5 }" do
        before do
          @scope = Scope.new
          @scope.push( :directory => :directory1, :data => :db1 )
          @scope.push( :data => :db3 )
          @scope.push( :master_shard )
          @scope.push( :main => :db5 )
        end

        it "should return :master_shard for :data" do
          @scope.active_shard_for_schema( :data ).should == :master_shard
        end

        it "should return :master_shard for :directory" do
          @scope.active_shard_for_schema( :directory ).should == :master_shard
        end

        it "should return :master_shard for :aux" do
          @scope.active_shard_for_schema( :aux ).should == :master_shard
        end

        it "should return :db5 for :main" do
          @scope.active_shard_for_schema( :main ).should == :db5
        end
      end
    end

    describe "#pop( memento )" do
      it "should return scope to memento-ized state" do
        scope = Scope.new

        memento = scope.push( :directory => :directory1, :data => :db1 )
        scope.push( :data => :db3 )

        scope.pop( memento )

        scope.active_shard_for_schema( :directory ).should be_nil
        scope.active_shard_for_schema( :data ).should be_nil
      end

      it "should remove one scope if none is specified" do
        scope = Scope.new
        scope.push( :directory => :directory1, :data => :db1 )
        scope.push( :data => :db3 )

        scope.pop()

        scope.active_shard_for_schema( :directory ).should == :directory1
        scope.active_shard_for_schema( :data ).should == :db1
      end

      it "should correctly remove an entry with an AnyShard entry behind it" do
        scope = Scope.new
        scope.push( :directory => :directory2 )
        scope.push( :data => :db3 )
        scope.push( :master_shard )
        scope.push( :data => :db6 )

        scope.pop

        scope.active_shard_for_schema( :directory ).should == :master_shard
        scope.active_shard_for_schema( :data ).should == :master_shard
        scope.active_shard_for_schema( :aux ).should == :master_shard
      end

      it "should correctly remove an AnyShard entry" do
        scope = Scope.new
        scope.push( :directory => :directory2 )
        memento = scope.push( :directory => :directory1, :data => :db1 )
        scope.push( :data => :db3 )
        scope.push( :master_shard )
        scope.push( :data => :db6 )
        scope.push( :directory => :directory5 )

        scope.pop( memento )

        scope.active_shard_for_schema( :directory ).should == :directory2
        scope.active_shard_for_schema( :data ).should be_nil
        scope.active_shard_for_schema( :aux ).should be_nil
      end
    end

    describe "#push(...)" do
      it "should return a scope memento" do
        scope = Scope.new
        scope.push( :data => :db8 ).should be_kind_of( Scope::Memento )
      end
    end

  end

end