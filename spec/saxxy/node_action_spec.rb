require "spec_helper"
require "saxxy/node_rule"
require "saxxy/node_action"


describe Saxxy::NodeAction do
  let(:rule) { Saxxy::NodeRule.new("div") }

  describe "#initialize" do
    it "initializes with an activation rule and with a block" do
      block = ->() { "this is a test block" }
      action = Saxxy::NodeAction.new(rule, &block)
      action.action.should == block
      action.activation_rule.should == rule
    end

    it "initializes with the id block if none is given" do
      Saxxy::NodeAction.new(rule).action.call("foo").should == "foo"
    end
  end

  describe "#matches" do
    it "should delegate the call to activation_rule" do
      action = Saxxy::NodeAction.new(rule)
      args = ["div", { class: /foo/ }]
      action.activation_rule.should_receive(:matches).with(*args)
      action.matches(*args)
    end
  end

  describe "#call" do
    it "should delegate the call to an instance exec on the binding i.e. context if a context is given" do
      a_context = Object.new
      action = Saxxy::NodeAction.new(rule, a_context)
      a_context.should_receive(:instance_exec).with(["foo"], &action.action)
      action.call("foo")
    end

    it "should delegate the call to an instance exec on itself if no context is given" do
      action = Saxxy::NodeAction.new(rule)
      action.should_receive(:instance_exec).with(["foo"], &action.action)
      action.call("foo")
    end
  end

end
