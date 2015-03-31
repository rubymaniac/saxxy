require "saxxy/utils/callback_array"
require "saxxy/context"
require "saxxy/node_rule"
require "saxxy/event_registry"
require "saxxy/context_tree"
require "saxxy/callbacks/sax"


describe Saxxy::Callbacks::SAX do

  # A class that includes the SAXCallbacks functionality
  let(:klass) do
    Class.new do
      include Saxxy::Callbacks::SAX
      attr_reader :active_pool, :inactive_pool, :event_registry
    end
  end

  # Helper methods
  def get_level(obj = subject)
    obj.instance_variable_get("@deactivation_level")
  end

  def pool(type = :active, obj = subject)
    obj.instance_variable_get("@#{type}_pool")
  end

  def registry
    subject.event_registry.instance_variable_get("@actions")
  end

  def events
    registry.values
  end

  def actions
    registry.keys
  end


  describe "#initialize" do
    let(:context) do
      Saxxy::ContextTree.new do
        under("div", class: "foo") do
          under("span", title: /bar/)
        end

        under("table")
      end.root
    end
    let(:subject) { klass.new(context) }

    it "should set the active pool to a callback array" do
      subject.active_pool.should be_a(Saxxy::CallbackArray)
      subject.active_pool.instance_variable_get("@add_callback").should_not be_nil
    end

    it "should set the inactive pool to a callback array" do
      subject.inactive_pool.should be_a(Saxxy::CallbackArray)
      subject.inactive_pool.instance_variable_get("@add_callback").should_not be_nil
    end

    it "should set the event registry" do
      subject.instance_variable_get("@event_registry").should be_a(Saxxy::EventRegistry)
    end

    it "should have the context in the active_pool" do
      subject.active_pool.to_a.should == [context]
    end

    it "should have the children of the context in the inactive_pool" do
      subject.inactive_pool.to_a.should have(2).contexts
      subject.inactive_pool.to_a.should == context.child_contexts
    end
  end


  describe "#on_start_element" do
    let(:context) do
      Saxxy::ContextTree.new do
        under("div", class: "foo") do
          on("ul") {}
          under("span", title: /bar/) {}
        end

        under("table") do
          on("tr") {}
        end
      end.root
    end
    let(:subject) { klass.new(context) }

    it "should not add any contexts to active pool if there is no context matching on the level" do
      expect { subject.on_start_element("div4", class: "foo") }.to_not change { subject.active_pool.to_a }
    end

    it "should add the matching contexts to the active pool" do
      subject.active_pool.to_a.should have(1).context
      subject.on_start_element("div", class: "foo")
      subject.active_pool.to_a.should have(2).contexts
      subject.active_pool.to_a.last.activation_rule.element.should == "div"
    end

    it "should remove the matching contexts from tha inactive pool and add them to the active" do
      matching = subject.inactive_pool.to_a.first
      subject.on_start_element("div", class: "foo")
      subject.inactive_pool.to_a.should_not include(matching)
      subject.active_pool.to_a.should include(matching)
    end

    it "should add the child contexts of the matching ones to the inactive pool" do
      expect { subject.on_start_element("div", class: "foo") }.to change {
        subject.inactive_pool.to_a.map { |c| c.activation_rule.element }
      }.from(["div", "table"]).to(["table", "span"])
    end

    it "should add the actions of the active contexts to the event registry" do
      expect do
        subject.on_start_element("div", class: "foo")
        subject.on_start_element("ul", class: "whateva")
      end.to change { actions.map { |a| a.activation_rule.element } }.from([]).to(["ul"])
    end

    it "should not add the actions of the inactive contexts to the registry" do
      expect do
        subject.on_start_element("table", class: "foo")
        subject.on_start_element("tr", class: "whateva")
      end.to_not change { actions.map { |a| a.activation_rule.element } }.from([]).to(["ul"])
    end

    it "should change the level on the activated contexts" do
      matching = subject.inactive_pool.to_a.first
      expect { subject.on_start_element("div", class: "foo") }.to change { get_level(matching) }.by(1)
    end

    it "should open the activated contexts" do
      matching = subject.inactive_pool.to_a.first
      expect do
        subject.on_start_element("div", class: "foo")
      end.to change { matching.send(:closed?) }.from(true).to(false)
    end

    it "should add an event if an action mathces the node" do
      expect do
        subject.on_start_element("div", class: "foo")
        3.times { subject.on_start_element("ul", class: "whateva") }
      end.to change { registry.values.flatten.size }.by(3)
    end

    it "should change the level on the activated events if matches node" do
      expect do
        subject.on_start_element("div", class: "foo")
        subject.on_start_element("ul", class: "whateva")
      end.to change {
        registry.values.first ? get_level(registry.values.first.last) : Saxxy::Activatable::DLEVEL_MIN
      }.by(1)
    end

    it "should not change the level on previously activated events that match the node" do
      subject.on_start_element("div", class: "foo")
      subject.on_start_element("ul", class: "whateva")
      previous = registry.values.first.last
      expect { subject.on_start_element("ul", class: "whateva") }.to_not change { get_level(previous) }
    end

    it "should not change the level on previously activated events that do not match the node" do
      subject.on_start_element("div", class: "foo")
      subject.on_start_element("ul", class: "whateva")
      previous = registry.values.first.last
      expect { subject.on_start_element("ul2", class: "whateva") }.to_not change { get_level(previous) }
    end

    it "should call register_and_activate_events_on" do
      subject.should_receive(:register_and_activate_events_on).with("ul", class: "foo")
      subject.on_start_element("ul", class: "foo")
    end

    it "should call register_event_from_action on any matching action" do
      subject.on_start_element("div", class: "foo")
      subject.on_start_element("table", class: "foo")
      subject.should have(2).actions
      matching = subject.send(:actions).select { |a| a.matches("ul", class: "whateva") }.first
      subject.should_receive(:register_event_from_action).with(matching, "ul", class: "whateva")
      subject.on_start_element("ul", class: "whateva")
    end

    it "should call activate_events_on" do
      subject.should_receive(:activate_events_on).with("ul", class: "foo")
      subject.on_start_element("ul", class: "foo")
    end

    it "should call register_and_activate_events_on" do
      subject.should_receive(:activate_contexts_on).with("ul", class: "foo")
      subject.on_start_element("ul", class: "foo")
    end
  end


  describe "#on_characters" do
    let(:context) do
      Saxxy::ContextTree.new do
        under("div", class: "foo") do
          on("ul") {}
          on("span") {}
          under("span", title: /bar/) {}
        end

        under("table") do
          on("tr") {}
        end
      end.root
    end
    let(:subject) { klass.new(context) }

    # Activate the first context and the first action
    before do
      subject.on_start_element("div", class: "foo")
      subject.on_start_element("ul", {})
    end

    it "should add the text on the last activated event for the matching actions" do
      expect do
        subject.on_start_element("ul", {})
        subject.on_characters("some chars")
      end.to change { events.flatten.map(&:text) }.from([""]).to(["", "some chars"])
    end

    it "should append the text for as many times it is called" do
      expect do
        subject.on_characters("count")
        5.times { |i| subject.on_characters(" #{i+1}") }
      end.to change { events.flatten.map(&:text) }.from([""]).to(["count 1 2 3 4 5"])
    end

    it "should append nothing if called with a nil argument" do
      expect do
        subject.on_characters(nil)
      end.to_not change { events.flatten.map(&:text) }
    end
  end


  describe "#on_end_element" do
    let(:context) do
      Saxxy::ContextTree.new do
        under("div", class: "foo") do
          on("ul") {}
          on("span") {}
          under("span", title: /bar/) {}
        end

        under("table") do
          on("tr") {}
          on("td") {}
        end
      end.root
    end
    let(:subject) { klass.new(context) }

    context "events" do
      # Activate an event
      before do
        subject.on_start_element("div", class: "foo")
        subject.on_start_element("ul", {})
      end

      it "should remove the events that are closed from the registry" do
        # Activate another event in order to have 2 events for that action
        subject.on_start_element("ul", {})
        events.flatten.should have(2).events
        removed_event = events.flatten.last
        removed_event.should_not be_closed
        subject.on_end_element("ul")
        removed_event.should be_closed
        events.flatten.should_not include(removed_event)
      end

      it "should call the action of the closed events with the appended text" do
        removed_event = events.flatten.last
        removed_event.action.should_receive(:call).with("foo", "ul", {})
        subject.on_characters("foo")
        subject.on_end_element("ul")
        removed_event.should be_closed
      end

      it "should not remove the still opened events" do
        subject.on_start_element("ul", {})
        events.flatten.should have(2).events
        not_removed = events.flatten.first
        subject.on_end_element("ul")
        events.flatten.should include(not_removed)
      end

      # Note: If we assert that the action of the not removed event should not
      #       receive :call it will be a false assertion due to the fact that
      #       the events are pointing to the same action object.
      it "should not call the action of the still opened events" do
        subject.on_start_element("ul", {})
        not_removed = events.flatten.first
        not_removed.should_not_receive(:fire)
        subject.on_end_element("ul")
        not_removed.should_not be_closed
      end
    end

    context "contexts" do
      before { subject.on_start_element("table", class: "foo") }

      it "should remove a closed context from the active pool" do
        removed = pool.to_a.last
        pool.to_a.should include(removed)
        subject.on_end_element("table")
        pool.to_a.should_not include(removed)
      end

      it "should not remove an open context from the active pool" do
        not_removed = pool.last
        pool.should include(not_removed)
        subject.on_end_element("foo")
        pool.should include(not_removed)
      end

      it "should not empty the active pool if there is other contexts in" do
        subject.on_start_element("div", class: "foo")
        subject.on_start_element("span", title: "foobar")
        expect do
          subject.on_end_element("span")
          subject.on_end_element("div")
        end.to change { pool.length }.from(4).to(2)
      end
    end


    context "private methods" do
      let(:context) do
        Saxxy::ContextTree.new do
          under("div", class: "foo") do
            on("ul") {}
            on("span") {}
            under("span", title: /bar/) {}
          end

          under("table") do
            on("tr") {}
            on("td") {}
          end
        end.root
      end
      let(:subject) { klass.new(context) }


      describe "#actions" do
        before { subject.on_start_element("table", class: "foo") }

        it "should contain the actions of the active contexts" do
          subject.send(:actions).should == pool.last.actions
        end

        it "should not contain the actions of the inactive contexts" do
          actions = subject.send(:actions)
          actions.length.should_not be_zero
          pool(:inactive).flat_map(&:actions).each do |action|
            actions.should_not include(action)
          end
        end
      end


      describe "#on_remove_from_active_pool" do
        # This will happen only if the html is malformed
        it "should remove actions that are still in the registry" do
          subject.on_start_element("table", class: "foo")
          subject.on_start_element("tr", class: "foo")
          expect do
            subject.send(:on_remove_from_active_pool, pool.last)
          end.to change { registry.values.empty? }.from(false).to(true)
        end

        it "should push the context back to the inactive pool if it's parent is in the active pool"
      end


      describe "#on_add_to_active_pool" do
        it "will transfer it's child contexts into the inactive pool" do
          div_context = context.child_contexts.first
          div_context.child_contexts.should_not be_empty
          div_context.child_contexts.each { |c| pool(:inactive).should_not include(c) }
          subject.send(:on_add_to_active_pool, div_context)
          div_context.child_contexts.each { |c| pool(:inactive).should include(c) }
        end

        it "should set the on_deactivation callback on the context" do
          ctx = Saxxy::Context.new
          ctx.should_receive(:on_deactivation)
          subject.send(:on_add_to_active_pool, ctx)
        end
      end


      describe "#on_add_to_inactive_pool" do
        it "should set the on_activation callback on the context" do
          ctx = Saxxy::Context.new
          ctx.should_receive(:on_activation)
          subject.send(:on_add_to_inactive_pool, ctx)
        end
      end


      describe "#deactivate_contexts_on" do
        it "should call deactivate_on on every context in active pool" do
          subject.on_start_element("table")
          pool.each { |c| c.should_receive(:deactivate_on).with("span") }
          subject.send(:deactivate_contexts_on, "span")
        end

        it "should not call deactivate_on on contexts in inactive pool" do
          subject.on_start_element("table")
          pool(:inactive).each { |c| c.should_not_receive(:deactivate_on) }
          subject.send(:deactivate_contexts_on, "span")
        end
      end


      describe "#activate_contexts_on" do
        it "should call deactivate_on on every context in active pool" do
          subject.on_start_element("table")
          pool(:inactive).each { |c| c.should_receive(:activate_on).with("span", class: "foo") }
          subject.send(:activate_contexts_on, "span", class: "foo")
        end

        it "should not call deactivate_on on contexts in inactive pool" do
          subject.on_start_element("table")
          pool.each { |c| c.should_not_receive(:activate_on) }
          subject.send(:activate_contexts_on, "span", class: "foo")
        end
      end


      describe "#register_and_activate_events_on" do
        it "should call register_event_from_action with any matching action as argument" do
          a1, a2 = Object.new, Object.new
          a1.should_receive(:matches).and_return(true)
          a2.should_receive(:matches).and_return(false)
          subject.stub(actions: [a1, a2])
          subject.should_receive(:register_event_from_action).with(a1, "div", class: "foo")
          subject.send(:register_and_activate_events_on, "div", class: "foo")
        end

        it "should call the activate_events_on with same arguments" do
          subject.should_receive(:activate_events_on).with("div", class: "foo")
          subject.send(:register_and_activate_events_on, "div", class: "foo")
        end
      end
    end
  end
end
