require "saxxy/activatable"


module Saxxy

  ##
  # @author rubymaniac
  #
  # An Event refers to a specific NodeAction and is what
  # is registered when a NodeAction matches a specific node.
  # Because a NodeAction may match more than one node many
  # events, under this action, should get registered.
  #
  #
  # @!attribute [r] text
  #   @return [String] the text under the matching node
  #
  # @!attribute [r] attributes
  #   @return [Hash] the attributes of the matching node
  #
  # @!attribute [r] element_name
  #   @return [Hash] the name of the matching node
  #
  # @!attribute [r] action
  #   @return [NodeAction] the underlying NodeAction
  ##
  class Event
    include Activatable

    attr_reader :text, :attributes, :element_name, :action

    # Initializes an Event with an associated NodeAction
    #
    # @param action [NodeAction] this event's action
    #
    def initialize(action)
      @action = action
      initialize_options
      initialize_activatable(action.activation_rule)
    end

    # Appends the argument to the event's text attribute
    #
    # @param text [NodeAction] the text to append
    #
    # @return text [String] the event's text
    def append_text(text)
      @text += text
      @text
    end

    # Merges the argument hash to the event's attributes
    #
    # @param attrs [Hash] the attributes to merge
    #
    # @return attributes [Hash] the event's attributes
    def merge_attributes(attrs)
      @attributes.merge!(attrs)
    end

    # Changes the element_name
    #
    # @param name [String] the new element_name
    #
    # @return element_name [String] the event's element_name
    def set_element_name(name)
      @element_name = name
    end

    # Calls the action with the text, element_name, attributes
    def fire
      action.call(text, element_name, attributes)
    end

    private
    def initialize_options
      @text = ""
      @element_name = nil
      @attributes = {}
    end
  end

end
