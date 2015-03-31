require "spec_helper"
require "saxxy/node_rule"
require "saxxy/node_action"
require "saxxy/context"


describe Saxxy::Context do
  let(:rule) { Saxxy::NodeRule.new("div") }

  it "should include activatable" do
    Saxxy::Context.ancestors.should include(Saxxy::Activatable)
  end

  describe "#initialize" do
    it "should start with empty child_contexts and actions" do
      subject.actions.should be_empty
      subject.child_contexts.should be_empty
    end

    it "should start with an activation rule if one is given" do
      subject.activation_rule.should be_nil
      Saxxy::Context.new(rule).activation_rule.should == rule
    end
  end

  # #register action is used to register either an action or a child context
  describe "#register" do
    it "should add an action in the actions array if argument is a NodeAction" do
      action = Saxxy::NodeAction.new(rule)
      expect { subject.register("foo") }.to_not change { subject.actions }
      expect { subject.register(action) }.to change { subject.actions }.by([action])
    end

    it "should add a child context and change its parent to self if argument is a Context" do
      ctx = Saxxy::Context.new(rule)
      ctx.parent_context.should be_nil
      subject.register(ctx).child_contexts.should == [ctx]
      ctx.parent_context.should == subject
    end
  end

  describe "#has_parent?" do
    it "returns false if the context has no parent" do
      ctx = Saxxy::Context.new(rule)
      ctx.has_parent?.should be_false
      subject.register(ctx)
      ctx.has_parent?.should be_true
    end
  end

end