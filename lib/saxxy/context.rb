require "saxxy/activatable"
require "saxxy/node_action"


module Saxxy

  ##
  # @author rubymaniac
  #
  # Context describes, semantically, an XML tag-context.
  # For example an XML tag-context: <div>This is a context</div>
  #
  # Whether a tag-context is described by a Context object
  # depends on whether the Context's activation rule matches
  # this tag-context. Because a Context can be activated
  # on a tag-context that matches it's activation rule
  # it includes the "Activatable" module.
  #
  # A context can belong to a parent context and thus it
  # may have a `parent_context` attribute that points to
  # it's parent. A context may also have `child_contexts`.
  #
  # @!attribute [r] activation_rule
  #   @return [NodeRule] this context's activation rule
  #
  # @!attribute [r|w] parent_context
  #   @return [Context] this context's parent
  #
  # @!attribute [r] child_contexts
  #   @return [Array<Context>] this context's immediate descendants
  ##
  class Context
    include Activatable

    attr_accessor :parent_context
    attr_reader :child_contexts, :actions

    # Initializes a context with an `activation_rule` (defaults to `nil`).
    #
    # @param activation_rule [NodeRule] an instance of NodeRule or nil to
    #   declare that this context is automatically active.
    #
    def initialize(activation_rule = nil)
      @child_contexts = []
      @actions = []
      initialize_activatable(activation_rule)
    end

    # Registers either a Context as a `child_context` by setting
    # it's `parent_context` attribute to itself and appending it to
    # the `child_contexts` array, or a NodeAction by appending it to
    # the `actions` array.
    #
    # @param obj [Context|NodeAction] An instance of Context or
    #   an instance of NodeAction.
    #
    # @return [Context] self, i.e. the context
    #
    def register(obj)
      case obj
      when Context
        obj.parent_context = self
        @child_contexts << obj
      when NodeAction
        @actions << obj
      end
      self
    end

    # Checks whether this context has a parent.
    #
    # @return [Boolean] true if it has a `parent_context`, false otherwise
    #
    def has_parent?
      !parent_context.nil?
    end

    # Checks whether this context is a root context,
    # i.e. it has no `parent_context`
    #
    # @return [Boolean] false if it has a `parent_context`, true otherwise
    #
    def root?
      !has_parent?
    end
  end

end
