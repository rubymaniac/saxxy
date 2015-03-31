require "saxxy/parsers/base"
require "saxxy/callbacks/nokogiri"


module Saxxy
  module Parsers

    class Nokogiri < Base
      def parse_string(string, encoding = 'UTF-8', &block)
        new_parser.parse_memory(string, encoding, &block)
      end

      def parse_file(path_to_file, encoding = 'UTF-8', &block)
        new_parser.parse_file(path_to_file, encoding, &block)
      end

      def parse_io(io, encoding = 'UTF-8', &block)
        new_parser.parse_io(io, encoding, &block)
      end

      private
      def new_parser
        ::Nokogiri::HTML::SAX::Parser.new(Saxxy::Callbacks::Nokogiri.new(context_tree.root))
      end
    end

  end
end
