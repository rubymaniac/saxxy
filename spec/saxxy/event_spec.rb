require "spec_helper"
require "saxxy/node_action"
require "saxxy/node_rule"
require "saxxy/event"


describe Saxxy::Event do

  def event(action = Saxxy::NodeAction.new(Saxxy::NodeRule.new("div")))
    Saxxy::Event.new(action)
  end

  it "should include activatable" do
    Saxxy::Event.ancestors.should include(Saxxy::Activatable)
  end

  describe "#initialize" do
    it "should set the action to the argument" do
      action = Saxxy::NodeAction.new(Saxxy::NodeRule.new("div"))
      event(action).action.should == action
    end

    it "should call initialize_activatable with the activation rule that action has" do
      rule = Saxxy::NodeRule.new("div")
      Saxxy::Event.any_instance.should_receive(:initialize_activatable).with(rule)
      event(Saxxy::NodeAction.new(rule))
    end

    it "should set the text instance variable to an empty string" do
      event().text.should == ""
    end
  end

  describe "#append_text" do
    it "appends the text provided as an argument to the @text instance variable" do
      e = event()
      expect { e.append_text("foo") }.to change { e.text }.from("").to("foo")
    end
  end

  describe "#fire" do
    it "should delegate the call to the action with the text as the argument" do
      e = event()
      e.action.should_receive(:call).with(e.text, nil, {})
      e.fire
    end
  end

end
