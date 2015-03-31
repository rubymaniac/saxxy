require "saxxy/event"


module Saxxy

  ##
  # @author rubymaniac
  #
  # The Event Registry is in charge of registering new events
  # and firing the event callback whenever a specific event gets
  # deactivated.
  #
  # The registry has an @actions instance variable that holds
  #
  ##
  class EventRegistry

    # Initializes an empty Event Registry
    #
    def initialize
      clear
    end

    # Registers an event into the registry by initializing it and setting
    # its element_name and attributes accordingly.
    #
    # @param action [NodeAction] the action under which the event is registered
    # @param name [String] the element_name for the event
    # @param attributes [Hash] the attributes for the event
    #
    # @return event [Event] the registered event
    #
    def register_event_from_action(action, name = nil, attributes = {})
      new_event_for(action).tap do |e|
        e.set_element_name(name)
        e.merge_attributes(attributes)
        self[action] << e
      end
    end

    # Loops through the active actions (those registered) and takes the last,
    # i.e. active, event.
    #
    # @return events [Array] all the active events
    #
    def events
      @actions.values.map(&:last)
    end

    # Appends the text on every active event
    #
    # @param text [String] the text to append
    #
    # @return events [Array] all the active events
    #
    def push_text(text)
      send_on_each_event(:append_text, text)
    end

    # Deactivate the active events on a specific node
    #
    # @param element_name [String] the element name
    #
    # @return events [Array] all the active events
    #
    def deactivate_events_on(element_name)
      send_on_each_event(:deactivate_on, element_name)
    end

    # Activate the active events on a specific node. This is done
    # in order to increase the events' internal counter.
    #
    # @param element_name [String] nodes' element name
    # @param attributes [Hash] nodes' attributes
    #
    # @return events [Array] all the active events
    #
    def activate_events_on(element_name, attributes)
      send_on_each_event(:activate_on, element_name, attributes)
    end

    # Deletes the provided actions from the @actions without
    # firing any callbacks.
    #
    # @param actions [Array] actions to be removed
    #
    # @return actions [Hash] the registered actions
    #
    def remove_actions!(*actions)
      actions.each { |a| @actions.delete(a) }
      @actions
    end

    # Clears all registered actions
    #
    def clear
      @actions = {}
    end

    private
    def new_event_for(action)
      Saxxy::Event.new(action).on_deactivation do |ev|
        ev.fire
        unregister_event(action, ev)
      end
    end

    def unregister_event(action, event)
      self[action].delete(event)
      self[action].last ? self[action].last.append_text(event.text) : @actions.delete(action)
    end

    def [](action)
      @actions[action] ||= []
    end

    def send_on_each_event(method, *args)
      events.each { |e| e.public_send(method, *args) }
    end
  end

end
