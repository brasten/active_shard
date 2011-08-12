require 'spec_helper'
require 'active_shard/scope'


describe ActiveShard::Scope do

  context "with scopes: { directory: :directory1, data: db1 }, { data: :db3 }" do

    before do
      @scope = ActiveShard::Scope.new
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

  describe "#pop" do

    it "should remove all scopes back to specified argument" do
      @shard = { :directory => :directory1, :data => :db1 }

      @scope = ActiveShard::Scope.new
      @scope.push( @shard )
      @scope.push( :data => :db3 )

      @scope.pop( @shard )

      @scope.active_shard_for_schema( :directory ).should be_nil
    end


  end

end