require "spec_helper"
require "saxxy/utils/agent"
require "saxxy/context_tree"


describe "Saxxy::Parsers::Libxml", :not_jruby do

  def parser(*args)
    Saxxy::Parsers::Libxml.new(*args)
  end


  describe "#initialize" do
    let(:tree) { Saxxy::ContextTree.new {} }
    let(:subject) { parser(tree, {foo: :bar}) }

    it "should set the options" do
      subject.options.should == {foo: :bar}
    end

    it "should set the context tree" do
      subject.context_tree.should == tree
    end
  end


  context "integration" do
    let(:valid) do
      "<html><div><span class='fo'></span></div><div class='f'></div></html>"
    end

    let(:not_closed) do
      "<html><div><span class='fo'></span><div class='f'></div></html>"
    end

    let(:not_opened) do
      "<html><div></span></div><div></div></html>"
    end

    let(:tree) do
      Saxxy::ContextTree.new do
        on("div", class: nil) do |text, elem, attrs|
          @counts[:div] += 1
        end
        under("div") do
          on("span", class: /foo?/) do |text, elem, attrs|
            @counts[:span] += 1
          end
        end
      end
    end

    def parse(string, tree)
      parser(tree).parse_string(string)
    end


    before { @counts = { div: 0, span: 0 } }

    describe "valid html" do
      it "should change the div count" do
        pending("Libxml generates double callbacks") do
          expect { parse(valid, tree) }.to change { @counts[:div] }.from(0).to(1)
        end
      end

      it "should change the span count" do
        pending("Libxml generates double callbacks") do
          expect { parse(valid, tree) }.to change { @counts[:span] }.from(0).to(1)
        end
      end
    end

    describe "not closed div" do
      it "should change the div count" do
        pending("Libxml does not handle malformed html") do
          expect { parse(not_closed, tree) }.to change { @counts[:div] }.from(0).to(1)
        end
      end

      it "should change the span count" do
        pending("Libxml does not handle malformed html") do
          expect { parse(not_closed, tree) }.to change { @counts[:span] }.from(0).to(1)
        end
      end
    end

    describe "not opened span" do
      it "should change the div count" do
        pending("Libxml does not handle malformed html") do
          expect { parse(not_opened, tree) }.to change { @counts[:div] }.from(0).to(2)
        end
      end

      it "should not change the span count" do
        pending("Libxml does not handle malformed html") do
          expect { parse(not_opened, tree) }.to_not change { @counts[:span] }
        end
      end
    end

  end

end