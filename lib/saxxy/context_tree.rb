require "saxxy/context"
require "saxxy/node_action"
require "saxxy/node_rule"


module Saxxy

  ##
  # @author rubymaniac
  #
  # ContextTree describes the tree of contexts that the user
  # eventually constructs by constraining NodeActions to be
  # active under some Context.
  #
  #
  # @!attribute [r|w] root
  #   @return [Context] the root context of the tree
  #
  ##
  class ContextTree
    attr_accessor :root

    # Initializes a ContextTree by passing an optional context to be used
    # by the actions in order to execute their action block and a block that
    # will be evaluated in order to create the intenal tree structure.
    #
    # @param ctx [Object] an object to be used by the NodeActions
    #   in order to evaluate their block
    #
    # @param block [Proc] a block that will get evaluated and create
    #   the context tree structure
    #
    def initialize(ctx = nil, &block)
      self.root = Saxxy::Context.new
      @ctx = ctx || eval("self", block.binding)
      eval_subtree!(&block)
    end

    # Creates a Context and uses the arguments to create its activation rule. After
    # creating the context it registers it under the current root context and returns it.
    #
    # @param regexp_or_string [String|Regexp] the activation rule's name
    # @param attributes [Hash] the activation rule's attributes
    # @param block [Proc] a block that will get evaluated and register
    #   the child contexts and the actions
    #
    # @return [Context] the registered Context
    def under(regexp_or_string, attributes = {}, &block)
      Saxxy::Context.new(Saxxy::NodeRule.new(regexp_or_string, attributes)).tap do |context|
        __register_context(context, &block)
      end
    end

    # Creates a NodeAction and uses the arguments to create its activation rule and registers
    # it under the current root context.
    #
    # @param regexp_or_string [String|Regexp] the activation rule's name
    # @param attributes [Hash] the activation rule's attributes
    # @param block [Proc] the NodeAction's action block that will get
    #   evaluated on the passed context at construction
    #
    # @return [NodeAction] the registered NodeAction
    def on(regexp_or_string, attributes = {}, &block)
      Saxxy::NodeAction.new(Saxxy::NodeRule.new(regexp_or_string, attributes), @ctx, &block).tap do |action|
        __register_action(action)
      end
    end

    private
    def eval_subtree!(&block)
      instance_eval(&block) if block_given?
      self.root = root.parent_context if root.has_parent?
    end

    def __register_action(action)
      root.register(action)
    end

    def __register_context(context, &block)
      root.register(self.root = context)
      eval_subtree!(&block)
    end
  end

end
