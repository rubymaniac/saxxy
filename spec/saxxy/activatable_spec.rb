require 'spec_helper'
require 'saxxy/node_rule'
require 'saxxy/activatable'


describe Saxxy::Activatable do

  let(:klass) do
    Class.new do
      include Saxxy::Activatable
      attr_reader :deactivation_level, :deactivation_callback, :activation_callback, :mode
    end
  end
  let(:subject) { klass.new }
  let(:rule) { Saxxy::NodeRule.new("div", class: /foo$/) }


  describe "#included" do
    it "should set an attribute reader for the activation_rule" do
      a_class = Class.new
      a_class.should_receive(:attr_reader).with(:activation_rule)
      Saxxy::Activatable.included(a_class)
    end
  end


  describe "#initialize_activatable" do
    it "should set the activation rule" do
      expect { subject.initialize_activatable(rule) }.to change { subject.activation_rule }.from(nil).to(rule)
    end

    it "should set the deactivation level" do
      expect { subject.initialize_activatable(rule) }.to change {
        subject.deactivation_level
      }.from(nil).to(Saxxy::Activatable::DLEVEL_MIN)
    end

    it "should set the mode to inactive" do
      expect { subject.initialize_activatable(rule) }.to change { subject.mode }.from(nil).to(:inactive)
    end
  end


  describe "#on_deactivation" do
    let(:block) { ->(e) { e } }

    it "should set the deactivation callback" do
      expect { subject.on_deactivation(&block) }.to change { subject.deactivation_callback }.to(block)
    end

    it "should return self" do
      subject.on_deactivation(&block).should == subject
    end
  end


  describe "#on_activation" do
    let(:block) { ->(e) { e } }

    it "should set the activation callback" do
      expect { subject.on_activation(&block) }.to change { subject.activation_callback }.to(block)
    end

    it "should return self" do
      subject.on_activation(&block).should == subject
    end
  end


  describe "#can_be_activated_on" do
    context "with activation rule" do
      let(:subject) { klass.new.tap { |i| i.initialize_activatable(rule) } }

      it "should return true if rule matches the node and is closed" do
        subject.stub(closed?: true)
        subject.send(:can_be_activated_on, "div", { class: "baz foo" }).should be_true
      end

      it "should return false if rule doen't match the node and is closed" do
        subject.stub(closed?: true)
        subject.send(:can_be_activated_on, "div", { class: "baz foo4" }).should be_false
      end

      it "should return false if rule matches and is not closed" do
        subject.stub(closed?: false)
        subject.send(:can_be_activated_on, "div", { class: "baz foo" }).should be_false
      end
    end

    context "without activation rule" do
      let(:subject) { klass.new.tap { |i| i.initialize_activatable(nil) } }

      it "should return true on any node if closed" do
        subject.stub(closed?: true)
        subject.send(:can_be_activated_on, "d**", { class: "cREfrt34%^f" }).should be_true
      end

      it "should return false on any node if not closed" do
        subject.stub(closed?: false)
        subject.send(:can_be_activated_on, "d**", { class: "cREfrt34%^f" }).should be_false
      end
    end
  end


  describe "#switch_to" do
    it "should change the mode to the specified argument" do
      expect { subject.send(:switch_to, :active) }.to change { subject.mode }.from(nil).to(:active)
    end
  end


  describe "#is" do
    it "should return true if is in the same mode as the argument" do
      subject.send(:switch_to, :active)
      subject.send(:is, :active).should be_true
    end

    it "should return false if is not in the same mode as the argument" do
      subject.send(:switch_to, :inactive)
      subject.send(:is, :active).should be_false
    end
  end


  describe "#activate_on" do
    context "inactive mode" do
      let(:callback) { ->(e) { e } }
      let(:subject) { klass.new.tap { |i| i.initialize_activatable(rule) }.on_activation(&callback) }

      it "should not run the callback if rule does not match" do
        args1 = ["div", { class: "foo4" }]
        args2 = ["span", { class: "foo" }]
        subject.activation_rule.matches(*args1).should be_false
        subject.activation_rule.matches(*args2).should be_false
        callback.should_not_receive(:call)
        subject.activate_on(*args1)
        subject.activate_on(*args2)
      end

      it "should run the callback if it has rule and matches the node" do
        args = ["div", { class: "foo" }]
        subject.activation_rule.matches(*args).should be_true
        callback.should_receive(:call)
        subject.activate_on(*args)
      end

      it "should not increment the level if it cannot be activated" do
        expect { subject.activate_on("div", class: "foo4") }.to_not change { subject.deactivation_level }
        expect { subject.activate_on("span", class: "foo") }.to_not change { subject.deactivation_level }
      end

      it "should increment the level if it can be activated" do
        expect { subject.activate_on("div", class: "foo") }.to change { subject.deactivation_level }.by(1)
      end

      it "should change the mode if it can be activated" do
        expect { subject.activate_on("div", class: "foo") }.to change {
          subject.mode
        }.from(:inactive).to(:active)
      end
    end

    context "active mode" do
      let(:subject) do
        klass.new.tap do |i|
          i.initialize_activatable(rule)
          i.activate_on("div", class: "foo")
        end
      end

      before { subject.send(:is, :active).should be_true }

      it "should not run the callback if it can be activated" do
        subject.on_activation(&->(){})
        subject.activation_callback.should_not_receive(:call)
        subject.activate_on("div", class: "foo")
      end

      it "should not increment the level if rule doesn't match element name" do
        expect { subject.activate_on("div3", class: "foo") }.to_not change { subject.deactivation_level }
      end

      it "should increment the level if rule matches element name" do
        expect { subject.activate_on("div", class: "foo43") }.to change { subject.deactivation_level }.by(1)
      end

      it "should not change the mode if rule matches element name" do
        expect { subject.activate_on("div", class: "foo") }.to_not change { subject.mode }
      end
    end
  end


  describe "#deactivate_on" do
    let(:callback) { ->(e) { e } }
    let(:subject) { klass.new.tap { |i| i.initialize_activatable(rule) }.on_deactivation(&callback) }

    context "inactive mode" do
      it "should not call decrement_level or deactivate! if rule does not match element name" do
        callback.should_not_receive(:call)
        subject.should_not_receive(:decrement_level)
        subject.should_not_receive(:deactivate!)
        subject.deactivate_on("divs")
      end

      it "should not call decrement_level or deactivate! if rule matches element name" do
        callback.should_not_receive(:call)
        subject.should_not_receive(:decrement_level)
        subject.should_not_receive(:deactivate!)
        subject.deactivate_on("div")
      end

      it "should not change the mode when is deactivated in a matching element name" do
        expect { subject.deactivate_on("div") }.to_not change { subject.mode }
      end

      it "should not change the mode when is deactivated in non matching element name" do
        expect { subject.deactivate_on("divd") }.to_not change { subject.mode }
      end
    end

    context "active mode" do
      before do
        subject.activate_on("div", class: "foo")
        subject.send(:is, :active).should be_true
      end

      it "should not run the callback if it isnt deactivated as many times as gets activated i.e. is not closed" do
        callback.should_not_receive(:call).with(subject)
        4.times { |i| subject.activate_on("div", class: "foo#{i}") }
        4.times { subject.deactivate_on("div") }
      end

      it "should run the deactivation callback if it is deactivated as many times as gets activated i.e. is closed" do
        callback.should_receive(:call).with(subject)
        3.times { |i| subject.activate_on("div", class: "foo#{i}") }
        4.times { subject.deactivate_on("div") }
      end

      it "should not change mode to inactive if it isnt deactivated as many times as gets activated i.e. is not closed" do
        expect do
          4.times { |i| subject.activate_on("div", class: "foo#{i}") }
          4.times { subject.deactivate_on("div") }
        end.to_not change { subject.mode }
      end

      it "should change mode to inactive if it is deactivated as many times as gets activated i.e. is closed" do
        expect do
          3.times { |i| subject.activate_on("div", class: "foo#{i}") }
          4.times { subject.deactivate_on("div") }
        end.to change { subject.mode }.from(:active).to(:inactive)
      end

      it "should run the deactivation callback if rule matches element name" do
        callback.should_receive(:call).with(subject)
        subject.deactivate_on("div")
      end

      it "should not run the deactivation callback if rule doesn't match element name" do
        callback.should_not_receive(:call).with(subject)
        subject.deactivate_on("divd")
      end

      it "should decrement the level when deactivated on a matching element name" do
        expect { subject.deactivate_on("div") }.to change { subject.deactivation_level }.by(-1)
      end

      it "should not decrement the level when deactivated on a non matching element name" do
        expect { subject.deactivate_on("divd") }.to_not change { subject.deactivation_level }
      end
    end
  end


  describe "#run_activation_callback" do
    let(:subject) { klass.new.tap { |i| i.initialize_activatable(rule) } }

    it "should call the activation_callback if it is present" do
      subject.on_activation(&->(){})
      subject.instance_variable_get("@activation_callback").should_receive(:call).with(subject)
      subject.send(:run_activation_callback)
    end

    it "should not call the activation_callback if it is not present" do
      allow_message_expectations_on_nil
      subject.instance_variable_get("@activation_callback").should_not_receive(:call).with(subject)
      subject.send(:run_activation_callback)
    end
  end


 describe "#run_deactivation_callback" do
   let(:subject) { klass.new.tap { |i| i.initialize_activatable(rule) } }

   it "should call the deactivation_callback if it is present" do
     subject.on_deactivation(&->(){})
     subject.instance_variable_get("@deactivation_callback").should_receive(:call).with(subject)
     subject.send(:run_deactivation_callback)
   end

   it "should not call the deactivation callback if it is not present" do
    allow_message_expectations_on_nil
     subject.instance_variable_get("@deactivation_callback").should_not_receive(:call).with(subject)
     subject.send(:run_deactivation_callback)
   end
 end


 describe "#increment_level" do
   let(:subject) { klass.new.tap { |i| i.initialize_activatable(rule) } }

   it "should increment the deactivation_level" do
     expect { subject.send(:increment_level) }.to change { subject.deactivation_level }.by(1)
   end
 end


 describe "#decrement_level" do
   let(:subject) { klass.new.tap { |i| i.initialize_activatable(rule) } }

   it "should decrement the deactivation_level" do
     expect { subject.send(:decrement_level) }.to change { subject.deactivation_level }.by(-1)
   end
 end


 describe "#rule_matches_element_name" do
   it "should return true if no activation rule" do
     subject.send(:rule_matches_element_name, "foo").should be_true
   end

   it "should return false if it has activation_rule and does not match the element name" do
     subject.initialize_activatable(rule)
     subject.send(:rule_matches_element_name, "foo").should be_false
   end

   it "should return true if it has activation_rule and does match the element name" do
     subject.initialize_activatable(rule)
     subject.send(:rule_matches_element_name, "div").should be_true
   end
 end

end
