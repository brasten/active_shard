require 'active_support/hash_with_indifferent_access'

module ActiveShard

  class ShardDefinition
    attr_accessor :schema
    attr_accessor :name

    class << self

      # Returns a hash with environments as the hash keys and
      # a list of ShardDefinitions as the hash values
      #
      # @param [String] file_name path to Yaml file
      #
      # @return [Hash] hash of environments and lists of Definitions
      #
      def from_yaml_file( file_name )
        from_yaml( File.open( file_name ).read() )
      end

      # Returns a hash with environments as the hash keys and
      # a list of ShardDefinitions as the hash values
      #
      # @param [String] yaml YAML string to parse
      #
      # @return [Hash] hash of environments and lists of Definitions
      #
      def from_yaml( yaml )
        hash = YAML.load( ERB.new( yaml ).result )

        from_hash( hash )
      end

      # Returns a hash with environments as the hash keys and
      # a list of ShardDefinitions as the hash values
      #
      # @param [Hash] hash raw hash in YAML-format
      #
      # @return [Hash] hash of environments and lists of Definitions
      #
      def from_hash( hash )
        definitions = {}

        hash.each_pair do |environment, schemas|
          schemas.each_pair do |schema, shards|
            shards.each_pair do |shard, spec|
              ( definitions[ environment.to_sym ] ||= [] ) << self.new( shard.to_sym,
                                                                        spec.merge( :schema => schema.to_sym ) )
            end
          end
        end

        definitions
      end

    end

    # Returns a new ShardDefinition
    #
    # @param [String] name name of the shard
    # @param [Hash] options
    # @option options [String] :schema name of the schema
    # @option options [String] :group group name of shard
    # @option options all other options passed as connection spec
    #
    def initialize( name, options={} )
      opts = options.dup

      @name                 = name.to_sym
      @schema               = ( ( sch = opts.delete( :schema ) ).nil? ? nil : sch.to_sym )
      self.connection_spec  = opts
    end

    def connection_adapter
      @connection_adapter ||= connection_spec[:adapter]
    end
    
    def connection_database
      @connection_database ||= connection_spec[:database]
    end

    def connection_spec=(val)
      @connection_spec = val.nil? ? nil : HashWithIndifferentAccess.new( val )
    end

    def connection_spec
      @connection_spec ||= {}
    end

    # Returns true if our schema == schema_name and neither
    # self#schema nor schema_name is nil. Returns false otherwise.
    #
    # @param [Symbol] schema_name
    #
    # @return [bool]
    #
    def belongs_to_schema?( schema_name )
      return false if ( schema.nil? || schema_name.nil? )

      ( schema.to_sym == schema_name.to_sym )
    end

    def ==( other )
      eql?( other )
    end

    def eql?( other )
      (self.name == other.name) &&
        (self.schema == other.schema) &&
        (self.connection_spec == other.connection_spec)
    end

    private

      def symbolize_keys( hash )
        ret = {}

        hash.each_pair do |k,v|
          ret[k.to_sym] = v
        end

        ret
      end
  end

end