require "saxxy/parsers/base"
require "saxxy/callbacks/libxml"


module Saxxy
  module Parsers

    class Libxml < Base
      def initialize(context_tree, options = {})
        super
        @__internal_context_options =
          case options[:mode]
          when :html, nil
            LibXML::XML::Parser::Options::RECOVER |
            LibXML::XML::Parser::Options::NOERROR |
            LibXML::XML::Parser::Options::NOWARNING |
            LibXML::XML::Parser::Options::NONET
          when :xml
            LibXML::XML::Parser::Options::RECOVER |
            LibXML::XML::Parser::Options::NONET
          end
      end

      def parse_string(string, encoding = LibXML::XML::Encoding::UTF_8)
        parse_with LibXML::XML::SaxParser.new(build_context(:string, string, encoding))
      end

      def parse_file(path_to_file, encoding = LibXML::XML::Encoding::UTF_8)
        parse_with LibXML::XML::SaxParser.new(build_context(:file, path_to_file, encoding))
      end

      def parse_io(io, encoding = LibXML::XML::Encoding::UTF_8)
        parse_with LibXML::XML::SaxParser.new(build_context(:io, io, encoding))
      end

      private
      def build_context(method, obj, encoding)
        LibXML::XML::Parser::Context.public_send(method, obj).tap do |ctx|
          ctx.options = @__internal_context_options
          ctx.encoding = encoding
          ctx.recovery = true
        end
      end

      def parse_with(parser)
        parser.callbacks = Saxxy::Callbacks::Libxml.new(context_tree.root)
        parser.parse
      end
    end

  end
end
