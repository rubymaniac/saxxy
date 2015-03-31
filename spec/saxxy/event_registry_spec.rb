require "spec_helper"
require "saxxy/node_rule"
require "saxxy/node_action"
require "saxxy/event_registry"


describe Saxxy::EventRegistry do

  def actions(reg = subject)
    reg.instance_variable_get("@actions")
  end


  describe "#initialize" do
    it "sets the actions to an empty hash" do
      actions(Saxxy::EventRegistry.new).should == {}
    end
  end


  describe "#register_event_from_action" do
    let(:rule) { Saxxy::NodeRule.new("div", { title: "foo" }) }
    let(:action) { Saxxy::NodeAction.new(rule) }

    it "should create the action entry with events as the value if it does not exist yet" do
      actions().should == {}
      event = subject.register_event_from_action(action)
      actions().should == { action => [event] }
    end

    it "should append the event to the action entry" do
      ev1 = subject.register_event_from_action(action)
      ev2 = subject.register_event_from_action(action)
      actions()[action].should == [ev1, ev2]
    end
  end


  describe "#events" do
    let(:rule1) { Saxxy::NodeRule.new("div", { class: /foo/ }) }
    let(:rule2) { Saxxy::NodeRule.new("div", { title: "foo" }) }
    let(:action1) { Saxxy::NodeAction.new(rule1) }
    let(:action2) { Saxxy::NodeAction.new(rule2) }

    it "should return an array consisting of the last event of each action" do
      5.times { subject.register_event_from_action(action1) }
      last_ev1 = subject.register_event_from_action(action1)
      5.times { subject.register_event_from_action(action2) }
      last_ev2 = subject.register_event_from_action(action2)
      subject.events.should == [last_ev1, last_ev2]
    end
  end


  describe "#push_text" do
    let(:rule1) { Saxxy::NodeRule.new("div", { class: /foo/ }) }
    let(:rule2) { Saxxy::NodeRule.new("div", { title: "foo" }) }
    let(:action1) { Saxxy::NodeAction.new(rule1) }
    let(:action2) { Saxxy::NodeAction.new(rule2) }

    it "should add the text to the events (last events)" do
      5.times { subject.register_event_from_action(action1) }
      last_ev1 = subject.register_event_from_action(action1)
      5.times { subject.register_event_from_action(action2) }
      last_ev2 = subject.register_event_from_action(action2)
      expect { subject.push_text("foo") }.to change {
        [last_ev1, last_ev2].map(&:text)
      }.from(["", ""]).to(["foo", "foo"])
    end
  end


  describe "#deactivate_events_on" do
    let(:rule1) { Saxxy::NodeRule.new("div", { class: /foo/ }) }
    let(:rule2) { Saxxy::NodeRule.new("span", { title: "foo" }) }

    it "should call deactivate_events_on on every event with the element name as argument" do
      last_ev1 = subject.register_event_from_action(a1 = Saxxy::NodeAction.new(rule1))
      last_ev2 = subject.register_event_from_action(a2 = Saxxy::NodeAction.new(rule2))
      last_ev1.should_receive(:deactivate_on).with("div")
      last_ev2.should_receive(:deactivate_on).with("div")
      subject.deactivate_events_on("div")
    end

    it "should not remove inactive events" do
      last_ev1 = subject.register_event_from_action(a1 = Saxxy::NodeAction.new(rule1))
      last_ev2 = subject.register_event_from_action(a2 = Saxxy::NodeAction.new(rule2))
      expect { subject.deactivate_events_on("div") }.to_not change { actions()[a1] }
      expect { subject.deactivate_events_on("div") }.to_not change { actions()[a2] }
    end

    it "should remove active events that match the element name" do
      last_ev11 = subject.register_event_from_action(a1 = Saxxy::NodeAction.new(rule1)).tap do |e|
        e.activate_on("div", "class" => "foo")
      end
      last_ev12 = subject.register_event_from_action(a1).tap { |e| e.activate_on("div", "class" => "foo") }
      last_ev21 = subject.register_event_from_action(a2 = Saxxy::NodeAction.new(rule2))
      expect {
        subject.deactivate_events_on("div")
      }.to change { actions()[a1] }.from([last_ev11, last_ev12]).to([last_ev11])
    end

    it "should delete the action if the last event gets removed" do
      last_ev1 = subject.register_event_from_action(a1 = Saxxy::NodeAction.new(rule1)).tap do |e|
        e.activate_on("div", "class" => "foo")
      end
      last_ev2 = subject.register_event_from_action(a2 = Saxxy::NodeAction.new(rule2))
      expect {
        subject.deactivate_events_on("div")
      }.to change { actions()[a1] }.from([last_ev1]).to(nil)
    end

    it "should not remove already activated events that don't match the element name" do
      last_ev1 = subject.register_event_from_action(a1 = Saxxy::NodeAction.new(rule1)).tap do |e|
        e.activate_on("div", "class" => "foo")
      end
      last_ev2 = subject.register_event_from_action(a2 = Saxxy::NodeAction.new(rule2))
      expect { subject.deactivate_events_on("span") }.to_not change { actions()[a1] }
      expect { subject.deactivate_events_on("span") }.to_not change { actions()[a2] }
    end

    it "should append the text of the removed event to the next one in the queue" do
      last_ev11 = subject.register_event_from_action(a1 = Saxxy::NodeAction.new(rule1)).tap do |e|
        e.append_text("foo")
        e.activate_on("div", "class" => "foo")
      end
      last_ev12 = subject.register_event_from_action(a1).tap do |e|
        e.append_text(" bar")
        e.activate_on("div", "class" => "foo")
      end
      last_ev21 = subject.register_event_from_action(a2 = Saxxy::NodeAction.new(rule2))
      expect {
        subject.deactivate_events_on("div")
      }.to change { last_ev11.text }.from("foo").to("foo bar")
    end
  end
end
