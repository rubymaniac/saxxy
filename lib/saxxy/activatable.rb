module Saxxy

  ##
  # @author rubymaniac
  #
  # Activatable contains all the logic for handling the
  # activation of an object, whether this is a Context or an Event
  # or any object that needs to be activated / deactivated multiple times.
  #
  # Any Activatable object needs to possess an activation_rule
  # (assuming automatic activation if activation_rule is nil) in
  # order to use this to activate / deactivate the object. Everytime
  # the activation_rule matches an opening node the object gets activated
  # (by incrementing the internal @deactivation_level) and can be
  # activated many times. Everytime the activation_rule matches a
  # closing node the object gets deactivated (by decrementing the internal
  # @deactivation_level variable) and can be deactivated many times.
  #
  # An Activatable object is considered inactive when it's @deactivation_level
  # equals DLEVEL_MIN i.e. when it has been deactivated as many times as it
  # has been activated.
  #
  # @!attribute [r] activation_rule
  #   @return [NodeRule] this objects' activation_rule
  ##
  module Activatable

    # The lowest integer the deactivation level can reach before the object
    # is considered inactive.
    #
    DLEVEL_MIN = -1

    # Sets an attribute reader to the receiver for the
    # activation rule.
    #
    def self.included(receiver)
      receiver.send(:attr_reader, :activation_rule)
    end

    # Initiates the activatable by setting the activation_rule to the
    # argument, setting the deactivation_level to DLEVEL_MIN and it's
    # state to inactive
    #
    # @param rule [NodeRule] an instance of NodeRule or nil to
    #   declare that this object is automatically active.
    #
    # @return [Symbol] its state (active or inactive)
    #
    def initialize_activatable(rule)
      @activation_rule = rule
      @deactivation_level = DLEVEL_MIN
      switch_to(rule ? :inactive : :active)
    end

    # Sets the callback to run when this object gets deactivated
    #
    # @param block [Proc] the code to be executed upon deactivation
    #
    # @return self
    #
    def on_deactivation(&block)
      @deactivation_callback = block
      self
    end

    # Sets the callback to run when this object gets activated
    #
    # @param block [Proc] the code to be executed upon activation
    #
    # @return self
    #
    def on_activation(&block)
      @activation_callback = block
      self
    end

    # Activates the object on an opening node if it is inactive and can be
    # activated on the node or it increments the @deactivation_level
    # if the activation_rule matches the element_name
    #
    # @param element_name [String] the nodes' element name
    # @param attributes [Hash<String, String>] the nodes' attributes
    #
    # @return self
    #
    def activate_on(element_name, attributes)
      if is(:inactive) && can_be_activated_on(element_name, attributes)
        activate!
      elsif is(:active) && rule_matches_element_name(element_name)
        increment_level
      end
      self
    end

    # Deactivates the object on a closing node. If the object is inactive
    # it does nothing, otherwise it decrements the @deactivation_level if
    # the activation_rule matches the element_name and deactivates the object
    # if the @deactivation_level is DLEVEL_MIN.
    #
    # @param element_name [String] the nodes' element name
    #
    # @return self
    #
    def deactivate_on(element_name)
      return unless is(:active)
      decrement_level if rule_matches_element_name(element_name)
      deactivate! if closed?
      self
    end

    private
    def activate!
      run_activation_callback
      increment_level
      switch_to(:active)
    end

    def deactivate!
      run_deactivation_callback
      switch_to(:inactive)
    end

    def is(mode)
      @mode == mode
    end

    def switch_to(mode)
      @mode = mode
    end

    def closed?
      @deactivation_level == DLEVEL_MIN
    end

    def increment_level
      @deactivation_level += 1
    end

    def decrement_level
      @deactivation_level -= 1
    end

    def run_activation_callback
      @activation_callback.call(self) if @activation_callback
    end

    def run_deactivation_callback
      @deactivation_callback.call(self) if @deactivation_callback
    end

    def rule_matches_element_name(element_name)
      activation_rule.nil? || activation_rule.match_element_name(element_name)
    end

    def can_be_activated_on(element_name, attributes)
      (activation_rule.nil? || activation_rule.matches(element_name, attributes)) && closed?
    end
  end

end
