require 'spec_helper'
require 'active_shard/shard_definition'

describe ActiveShard::ShardDefinition do

  describe ".new( :shard_one, schema: 'schema_one', host: 'host1', adapter: 'mysql2' )" do
    before do
      @definition = ActiveShard::ShardDefinition.new( :shard_one,
                                                      :schema => 'schema_one',
                                                      :host => 'host1',
                                                      :adapter => 'mysql2' )
    end

    it "should be instance of ActiveShard::ShardDefinition" do
      @definition.should be_kind_of(ActiveShard::ShardDefinition)
    end

    it "should have name of :shard_one" do
      @definition.name.should == :shard_one
    end

    it "should have schema of 'schema_one'" do
      @definition.schema.should == 'schema_one'
    end

    it "should belong to schema 'schema_one'" do
      @definition.belongs_to_schema?( :schema_one ).should be_true
    end

    it "should have connection spec with host: 'host1' and adapter: 'mysql2'" do
      @definition.connection_spec[:host].should == 'host1'
      @definition.connection_spec[:adapter].should == 'mysql2'
    end
  end

  describe ".from_yaml_file" do
    before do
      @result = ActiveShard::ShardDefinition.from_yaml_file( File.expand_path( '../../fixtures/shards.yml', __FILE__ ) )
    end

    it "should have 4 production shards" do
      @result[:production].should have(4).items
    end

    it "should have 2 development shards" do
      @result[:development].should have(2).items
    end

  end

end