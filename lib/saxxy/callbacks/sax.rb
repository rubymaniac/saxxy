require "forwardable"
require "saxxy/utils/callback_array"
require "saxxy/event_registry"


module Saxxy
  module Callbacks

    module SAX
      def self.included(base)
        base.extend Forwardable
        base.def_delegators :@event_registry, :activate_events_on, :deactivate_events_on,
          :push_text, :register_event_from_action, :remove_actions!
      end

      def initialize(context)
        initialize_state
        @active_pool << context
      end

      def on_start_element(name, attrs = {})
        register_and_activate_events_on(name, attrs)
        activate_contexts_on(name, attrs)
      end

      def on_characters(string)
        push_text(string || "")
      end

      def on_end_element(name)
        deactivate_events_on(name)
        deactivate_contexts_on(name)
      end

      def on_end_document
        @active_pool.clear
        @inactive_pool.clear
        @event_registry.clear
      end

      private
      def initialize_state
        @event_registry = EventRegistry.new
        @inactive_pool = CallbackArray.new.on_add(&method(:on_add_to_inactive_pool))
        @active_pool = CallbackArray.new.on_add(&method(:on_add_to_active_pool)).on_remove(&method(:on_remove_from_active_pool))
      end

      def register_and_activate_events_on(name, attrs)
        actions.select { |a| a.matches(name, attrs) }.each do |action|
          register_event_from_action(action, name, attrs)
        end
        activate_events_on(name, attrs)
      end

      def activate_contexts_on(name, attrs)
        @inactive_pool.each { |context| context.activate_on(name, attrs) }
      end

      def deactivate_contexts_on(name)
        @active_pool.each { |context| context.deactivate_on(name) }
      end

      def on_add_to_inactive_pool(context)
        context.on_activation do |context|
          @inactive_pool >> context
          @active_pool << context
        end
      end

      def on_add_to_active_pool(context)
        context.on_deactivation { |context| @active_pool >> context }
        context.child_contexts.each { |context| @inactive_pool << context }
      end

      def on_remove_from_active_pool(context)
        @inactive_pool << context if @active_pool.member?(context.parent_context)
        remove_actions!(*context.actions)
      end

      def actions
        @active_pool.flat_map(&:actions)
      end
    end

  end
end
