require 'spec_helper'
require 'active_shard/active_record'

module ActiveShard::ActiveRecord

  describe ConnectionSpecificationAdapter, "an instance from a ShardDefinition" do
    let :adapter do
      ConnectionSpecificationAdapter.new(
        ActiveShard::ShardDefinition.new( :shard_one,
                                          :schema => :schema_one,
                                          :adapter => :sqlite3,
                                          :database => "#{ARTIFACTS_PATH}/shard_one.db" )
      )
    end

    specify "#adapter_method should == 'sqlite3_connection'" do
      adapter.adapter_method.should == 'sqlite3_connection'
    end

    specify "#config should == { adapter: :sqlite3, database: '#{ARTIFACTS_PATH}/shard_one.db' }" do
      adapter.config.should == { :adapter => :sqlite3, :database => "#{ARTIFACTS_PATH}/shard_one.db" }
    end

  end


end