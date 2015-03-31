require "spec_helper"
require "saxxy/utils/agent"
require "saxxy/context_tree"


# We have :not_jruby here because travis-ci does not
# support C extensions for jruby.
describe "Saxxy::Parsers::Ox", :not_jruby do

  def parser(*args)
    Saxxy::Parsers::Ox.new(*args)
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


  describe "#parse_*" do
    let(:tree) { Saxxy::ContextTree.new {} }
    let(:subject) { parser(tree) }

    it "#parse_io should delegate the call to parse" do
      ::Ox.should_receive(:sax_parse)
      subject.parse_io(StringIO.new(""))
    end

    it "#parse_string should delegate the call to parse" do
      ::Ox.should_receive(:sax_parse)
      subject.parse_string("")
    end
  end



  context "node count" do
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
        expect { parse(valid, tree) }.to change { @counts[:div] }.from(0).to(1)
      end

      it "should change the span count" do
        expect { parse(valid, tree) }.to change { @counts[:span] }.from(0).to(1)
      end
    end

    describe "not closed div" do
      it "should change the div count" do
        expect { parse(not_closed, tree) }.to change { @counts[:div] }.from(0).to(1)
      end

      it "should change the span count" do
        expect { parse(not_closed, tree) }.to change { @counts[:span] }.from(0).to(1)
      end
    end

    describe "not opened span" do
      it "should change the div count" do
        expect { parse(not_opened, tree) }.to change { @counts[:div] }.from(0).to(2)
      end

      it "should not change the span count" do
        expect { parse(not_opened, tree) }.to_not change { @counts[:span] }
      end
    end
  end


  context "text aggregation" do
    let(:valid) do
      "<html>0<div>1<span class='fo'>2</span>3</div><div class='f'>4</div></html>"
    end

    let(:not_closed) do
      "<html>0<div>1<span class='fo'>2</span>3<div>4</div></html>"
    end

    let(:not_opened) do
      "<html>0<div>1</span>23</div><div>4</div></html>"
    end

    let(:tree) do
      Saxxy::ContextTree.new do
        on("div", class: nil) do |text, elem, attrs|
          @texts[:div] = (@texts[:div] || "") + text
        end
        under("div") do
          on("span", class: /foo?/) do |text, elem, attrs|
            @texts[:span] = (@texts[:span] || "") + text
          end
        end
      end
    end

    def parse(string, tree)
      parser(tree).parse_string(string)
    end


    before { @texts = { div: nil, span: nil } }

    describe "valid html" do
      it "should change the div text" do
        expect { parse(valid, tree) }.to change { @texts[:div] }.to("123")
      end

      it "should change the span text" do
        expect { parse(valid, tree) }.to change { @texts[:span] }.to("2")
      end
    end

    describe "not closed div" do
      it "should change the div text" do
        expect { parse(not_closed, tree) }.to change { @texts[:div] }.to("41234")
      end

      it "should change the span text" do
        expect { parse(not_closed, tree) }.to change { @texts[:span] }.to("2")
      end
    end

    describe "not opened span" do
      it "should change the div text" do
        expect { parse(not_opened, tree) }.to change { @texts[:div] }.to("1234")
      end

      it "should not change the span text" do
        expect { parse(not_opened, tree) }.to_not change { @texts[:span] }
      end
    end
  end

end
