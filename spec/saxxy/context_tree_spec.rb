require "spec_helper"
require "saxxy/node_rule"
require "saxxy/node_action"
require "saxxy/context_tree"


describe Saxxy::ContextTree do
  let(:subject) { Saxxy::ContextTree.new {} }

  describe "#initialize" do
    it "sets root to a new context without a rule" do
      subject.root.should be_a(Saxxy::Context)
      subject.root.activation_rule.should be_nil
    end

    it "should call the eval_subtree! with the provided block" do
      block = ->(){}
      Saxxy::ContextTree.any_instance.should_receive(:eval_subtree!).with(&block)
      Saxxy::ContextTree.new(&block)
    end
  end

  # Maybe we should make the #on action idempotent on the sense that it will merge
  # the actions (the blocks) if it is called with the same arguments more than once.
  describe "#on" do
    it "should not change the root context" do
      expect { subject.on("div", { class: /foo/ }) }.to_not change { subject.root }
    end

    it "creates an action and registers it on the root context" do
      expect { subject.on("div", { class: /foo/ }) }.to change { subject.root.actions.size }.by(1)
    end

    it "creates a rule for the action with the specified arguments" do
      subject.on("div", { class: /foo/ })
      subject.root.actions[0].activation_rule.element.should == "div"
      subject.root.actions[0].activation_rule.attributes.should == { "class" => /foo/ }
    end
  end

  describe "#under" do
    it "should add a child context to the root" do
      expect { subject.under("div", { class: /foo/ }) }.to change { subject.root.child_contexts.length }.by(1)
    end

    it "should create a tree of contexts if it has nested #under calls" do
      subject.under("div") do
        under("span") { under("ul") }
        under("div", class: "bar") { under("ul") { under("li", class: /foo/); under("span") } }
      end
      subject.root.should have(1).child_contexts
      subject.root.child_contexts[0].should have(2).child_contexts
      subject.root.child_contexts[0].child_contexts[0].should have(1).child_contexts
      subject.root.child_contexts[0].child_contexts[0].child_contexts[0].should have(0).child_contexts
      subject.root.child_contexts[0].child_contexts[1].should have(1).child_contexts
      subject.root.child_contexts[0].child_contexts[1].child_contexts[0].should have(2).child_contexts
    end

    it "should build an activation rule for the child context from arguments" do
      args = ["div", { class: /foo/ }]
      subject.under(*args)
      ctx = subject.root.child_contexts[0]
      ctx.activation_rule.element.should == "div"
      ctx.activation_rule.attributes.should == { "class" => /foo/ }
    end
  end

end
