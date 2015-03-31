require "ox"
require "saxxy/callbacks/sax"


module Saxxy
  module Callbacks

    class Ox < ::Ox::Sax
      include SAX

      def initialize(context)
        super(context)
        reset_state!
      end

      def start_element(name)
        on_start_element_after_attr_parsing
        reset_state!
        set_name(name)
      end

      def attr(name, value)
        push_attr(name, value)
      end

      def text(string)
        on_start_element_after_attr_parsing
        on_characters(string)
        unset_name
      end

      def end_element(name)
        on_start_element_after_attr_parsing
        on_end_element(name.to_s)
        reset_state!
      end

      private
      def reset_state!
        @__state = { attrs: {} }
      end

      def unset_name
        @__state.delete(:name)
      end

      def set_name(name)
        @__state[:name] = name.to_s
      end

      def push_attr(name, value)
        @__state[:attrs].merge!(name.to_s => value)
      end

      def on_start_element_after_attr_parsing
        on_start_element(@__state[:name], @__state[:attrs]) if start_element_found?
      end

      def start_element_found?
        !@__state[:name].nil?
      end
    end

  end
end

