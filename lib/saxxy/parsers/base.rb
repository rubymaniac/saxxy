module Saxxy
  module Parsers

    class NotImplemented < StandardError; end

    class Base
      attr_reader :context_tree, :options

      def initialize(context_tree, options = {})
        @context_tree = context_tree
        @options = options
      end

      def parse_file(path_to_file)
        raise NotImplemented
      end

      def parse_string(string)
        raise NotImplemented
      end

      def parse_io(io)
        raise NotImplemented
      end
    end

  end
end