require "saxxy/parsers/base"
require "saxxy/callbacks/ox"


module Saxxy
  module Parsers

    class Ox < Base
      def parse_string(string, encoding = nil)
        parse(StringIO.new(string), encoding)
      end

      def parse_file(path_to_file, encoding = nil)
        parse(File.new(path_to_file), encoding)
      end

      def parse_io(io, encoding = nil)
        parse(io, encoding)
      end

      private
      def parse(io, encoding)
        io.set_encoding(encoding) if encoding
        callbacks = Saxxy::Callbacks::Ox.new(context_tree.root)
        ::Ox.sax_parse(callbacks, io, {smart: true}.merge(options))
      end
    end

  end
end
