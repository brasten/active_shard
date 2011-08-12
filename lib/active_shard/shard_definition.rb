module ActiveShard

  class ShardDefinition
    attr_accessor :schema
    attr_accessor :name
    attr_writer :connection_spec

    class << self

      # Returns a hash with environments as the hash keys and
      # a list of ShardDefinitions as the hash values
      #
      # @param [String] file_name path to Yaml file
      #
      # @return [Hash] hash of environments and lists of Definitions
      #
      def from_yaml_file( file_name )
        definitions = {}

        hash = YAML.load( ERB.new( File.open( file_name ).read() ).result )

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

      @name             = name
      @schema           = opts.delete( :schema )
      @connection_spec  = symbolize_keys( opts )
    end

    def adapter_method
      "#{connection_spec[:adapter]}_connection"
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