require "spec_helper"
require "saxxy/node_rule"


describe Saxxy::NodeRule do

  describe "#matches" do
    it "should return false if @element does not match first argument as string" do
      nr = Saxxy::NodeRule.new("div")
      nr.element.should eql("div")
      nr.matches("span").should be_false
    end

    it "should return false if @element does not match first argument as regexp" do
      nr = Saxxy::NodeRule.new(/div/)
      nr.element.should be_a(Regexp)
      nr.matches("span").should be_false
    end

    it "should return true if @element matches first argument as string and empty @attributes" do
      nr = Saxxy::NodeRule.new("div")
      nr.attributes.should be_empty
      nr.matches("div").should be_true
    end

    it "should return true if @element matches first argument as regexp and empty @attributes" do
      nr = Saxxy::NodeRule.new(/^d[iv]+?/)
      nr.attributes.should be_empty
      nr.matches("div").should be_true
    end

    it "should return false if @element matches first argument as string
        and non-empty @attributes with keys not in second argument's keys" do
      nr = Saxxy::NodeRule.new("div", { class: /fooo?/ })
      nr.attributes.should_not be_empty
      nr.matches("div", { foo: "bar" }).should be_false
    end

    it "should return false if @element matches first argument as regexp
        and non-empty @attributes with keys not in second argument's keys" do
      nr = Saxxy::NodeRule.new(/div/, { class: /fooo?/ })
      nr.attributes.should_not be_empty
      nr.matches("div", { foo: "bar" }).should be_false
    end


    it "should return true if @element matches first argument as string
        and non-empty @attributes with keys in second argument's keys and
        at the same time same values should match" do
      nr = Saxxy::NodeRule.new("div", { class: /fooo?/ })
      nr.attributes.should_not be_empty
      nr.matches("div", { foo: "bar", class: "foo" }).should be_true
    end

    it "should return true if @element matches first argument as regexp
        and non-empty @attributes with keys in second argument's keys and
        at the same time same values should match" do
      nr = Saxxy::NodeRule.new(/div/, { class: "foo" })
      nr.attributes.should_not be_empty
      nr.matches("div", { foo: "bar", class: "foo" }).should be_true
    end
  end


  describe "#match_attributes" do
    it "should return true on any attrs hash if the attributes are empty" do
      nr = Saxxy::NodeRule.new(/div/)
      nr.match_attributes({class: "some class", title: "bar"}).should be_true
    end

    it "should return true if an attribute exists and is nil
        and the matching does not contain this attribute" do
      nr = Saxxy::NodeRule.new(/div/, class: nil)
      nr.match_attributes({}).should be_true
    end

    it "should return true if an attribute exists and is nil
        and the matching does contain this attribute and is nil" do
      nr = Saxxy::NodeRule.new(/div/, class: nil)
      nr.match_attributes({ class: nil }).should be_true
    end

    it "should return false if an attribute exists and is nil
        and the matching does contain this attribute and is not nil" do
      nr = Saxxy::NodeRule.new(/div/, class: nil)
      nr.match_attributes({ class: "foo" }).should be_false
    end

    it "should return true if it has a subset of the matching attributes" do
      nr = Saxxy::NodeRule.new(/div/, title: "foo", class: "bar")
      nr.match_attributes({ title: "foo", class: "bar", rel: "baz" }).should be_true
    end

    it "should return false if it has a superset of the matching attributes" do
      nr = Saxxy::NodeRule.new(/div/, title: "foo", class: "bar", rel: "baz")
      nr.match_attributes({ title: "foo", class: "bar" }).should be_false
    end
  end
end