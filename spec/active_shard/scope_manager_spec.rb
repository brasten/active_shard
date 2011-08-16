require 'spec_helper'
require 'active_shard/scope_manager'

module ActiveShard

  describe ScopeManager do
    describe "#scope_class" do
      it "should equal Scope by default" do
        manager = ScopeManager.new

        manager.scope_class.should == Scope
      end
    end

    context "when instantiated with :scope_class => @anon_scope" do
      before do
        @anon_scope = Class.new

        @manager = ScopeManager.new( :scope_class => @anon_scope )
      end

      it "should have anonymous scope class" do
        @manager.scope_class.should == @anon_scope
      end
    end

    describe "#push" do
      it "delegates to Thread local scope" do
        scope = mock(:scope)
        scope.should_receive(:push).with(:test_scope)

        Thread.current[:active_shard_scope] = scope

        ScopeManager.new.push( :test_scope )
      end
    end

    describe "#pop" do
      it "delegates to Thread local scope" do
        scope = mock(:scope)
        scope.should_receive(:pop)

        Thread.current[:active_shard_scope] = scope

        ScopeManager.new.pop()
      end
    end

    describe "#active_shard_for_schema" do
      it "delegates to Thread local scope" do
        scope = mock(:scope)
        scope.should_receive(:active_shard_for_schema).with(:test_scope)

        Thread.current[:active_shard_scope] = scope

        ScopeManager.new.active_shard_for_schema( :test_scope )
      end
    end

  end
  
end