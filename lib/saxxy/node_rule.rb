module Saxxy

  ##
  # @author rubymaniac
  #
  # NodeRule describes a rule that will be tested upon an XML node
  # and will check if the node satisfies this NodeRule.
  #
  # The NodeRule consists of two parts. The `element` part which
  # refers to what should hold for the node's name. It can be
  # either a String (where the strict equality is should hold) or
  # a Regexp (where the Regexp must match the node name).
  #
  # The other part is the `attributes` part which refers to what
  # should hold for the attributes of the node. It consists of key-value
  # pairs where the key is the attribute to check and the value is what
  # should hold for that attribute.
  #
  # @!attribute [r] element
  #   @return [String|Regexp] node's name rule
  #
  # @!attribute [r] attributes
  #   @return [Hash<String, String|Regexp>] node's attributes rule
  ##
  class NodeRule
    attr_reader :element, :attributes

    # Initializes a NodeRule with an `element` part and an `attributes` part.
    #
    # @param element [String|Regexp] what should hold for the node name
    # @param attributes [Hash<String, String|Regexp>]
    #   what should hold for node's attributes
    #
    def initialize(element, attributes = {})
      @element = element
      @attributes = Saxxy::Helpers.stringify_keys(attributes)
    end

    # Checks whether this NodeRule matches a node.
    #
    # @param element_name [String] node's name
    # @param attrs [Hash<String, String>] node's attributes
    #
    # @return [Boolean] whether this NodeRule matches the node
    #
    def matches(element_name, attrs = {})
      match_element_name(element_name) && match_attributes(attrs)
    end

    # Checks whether this NodeRule is equal to another.
    #
    # @param rule [NodeRule] the other NodeRule
    #
    # @return [Boolean] whether this NodeRule equals rule
    #
    def equals(rule)
      element == rule.element && attributes == rule.attributes
    end

    # Checks whether this NodeRule matches only the name of a node.
    #
    # @param element_name [String] node's name
    #
    # @return [Boolean] whether this NodeRule matches node's name
    #
    def match_element_name(element_name)
      match(element, element_name)
    end

    # Checks whether this NodeRule matches only the attributes of a node.
    #
    # @param attrs [Hash<String, String>] node's attributes
    #
    # @return [Boolean] whether this NodeRule matches node's attributes
    #
    def match_attributes(attrs)
      attrs = Saxxy::Helpers.stringify_keys(attrs)
      attributes.reduce(true) do |b, (k, v)|
        value = attrs[k]
        b && ((!value.nil? && match(v, value)) || (v.nil? && value.nil?))
      end
    end

    private
    def match(obj, value)
      obj.is_a?(Regexp) ? !obj.match(value).nil? : obj == value
    end
  end

end
