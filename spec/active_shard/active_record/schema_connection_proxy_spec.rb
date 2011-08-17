require 'spec_helper'

module ActiveShard::ActiveRecord

  describe SchemaConnectionProxy, "an instance" do
    before do
      @mock = mock( :target )
      @proxy = SchemaConnectionProxy.new( @mock )
    end

    it "should delegate :columns to target" do
      @mock.should_receive( :columns )

      @proxy.columns
    end

    it "should delegate :verify to target" do
      @mock.should_receive( :verify )

      @proxy.verify
    end

    it "should delegate :verify! to target" do
      @mock.should_receive( :verify! )

      @proxy.verify!
    end

    it "should delegate :run_callbacks to target" do
      @mock.should_receive( :run_callbacks )

      @proxy.run_callbacks
    end

    it "should delegate :_run_checkin_callbacks to target" do
      @mock.should_receive( :_run_checkin_callbacks )

      @proxy._run_checkin_callbacks
    end

    it "should delegate :disconnect! to target" do
      @mock.should_receive( :disconnect! )

      @proxy.disconnect!
    end

    it "should delegate :quote_table_name to target" do
      @mock.should_receive( :quote_table_name )

      @proxy.quote_table_name
    end

    it "should delegate :quote_value to target" do
      @mock.should_receive( :quote_value )

      @proxy.quote_value
    end

    it "should delegate :quote to target" do
      @mock.should_receive( :quote )

      @proxy.quote
    end

    it "should raise error on :execute" do
      lambda do
        @proxy.execute
      end.should raise_error( ActiveShard::NoActiveShardError )
    end

  end

end