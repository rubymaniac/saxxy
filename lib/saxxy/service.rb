require "saxxy/context_tree"


module Saxxy

  module Parsers
    autoload :Nokogiri, "saxxy/parsers/nokogiri"
    autoload :Ox, "saxxy/parsers/ox"
    autoload :Libxml, "saxxy/parsers/libxml"
  end

  class Service
    attr_reader :parser

    def initialize(parser, options = {}, &block)
      @parser = build_parser(parser, options, &block)
    end

    def parse_file(*args)
      @parser.parse_file(*args)
    end

    def parse_string(*args)
      @parser.parse_string(*args)
    end

    def parse_io(*args)
      @parser.parse_io(*args)
    end

    private
    def build_parser(parser, options, &block)
      ctx = eval("self", block.binding)
      parser_class_from(parser).new(Saxxy::ContextTree.new(ctx, &block), options)
    end

    def parser_class_from(obj)
      case obj
      when Symbol, String
        Saxxy::Parsers.const_get(Saxxy::Helpers.camelize(obj))
      else
        obj
      end
    end
  end

end
