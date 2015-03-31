module Saxxy

  ##
  # @author rubymaniac
  #
  # NodeAction describes something that should be run on a
  # node. In order to check whether to run this action it
  # accepts as the first argument an activation_rule.
  #
  #
  # @!attribute [r] activation_rule
  #   @return [Context] this action's activation rule
  #
  # @!attribute [r] action
  #   @return [Proc] the block of code that will run on a node
  ##
  class NodeAction
    attr_reader :activation_rule, :action

    # Initializes a NodeAction with an `activation_rule` a context to run
    # its action (block) and the block.
    #
    # @param activation_rule [NodeRule] an instance of NodeRule
    #   used to check whether to run this action on a node
    #
    # @param context [Object] a context (object) on which the block
    #   will be evaluated
    #
    # @param block [Proc] a block that will get evaluated on context
    #
    def initialize(activation_rule, context = self, &block)
      @activation_rule = activation_rule
      @ctx = context
      @action = block_given? ? block : ->(e) { e }
    end

    # Delegates the call to its `activation_rule`
    #
    # @param element_name [String] the name of a node
    #
    # @param attributes [Hash<String, String>] the attributes of a node
    #
    # @return [Boolean] whether it matches the node
    #
    def matches(element_name, attributes)
      activation_rule.matches(element_name, attributes)
    end

    # Evaluates the block that was given to the constructor on the context
    # and passes the arguments to the block
    #
    # @param args [Array] variable arguments that pass to the block
    #
    def call(*args)
      @ctx.instance_exec(args, &action)
    end
  end

end
