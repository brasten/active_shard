module ActiveShard

  # CODE CONVENTION VIOLATION
  #
  # For better visualization, the following code is indented based on class hierarchy rather
  # than nesting.
  #

  class ActiveShardError < StandardError; end

    class DefinitionError < ActiveShardError; end
      class NameNotUniqueError < DefinitionError; end

    class NoActiveShardError < ActiveShardError; end

end