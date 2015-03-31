require "libxml"
require "saxxy/callbacks/sax"


module Saxxy
  module Callbacks

    class Libxml
      include LibXML::XML::SaxParser::Callbacks
      include SAX

      def on_start_element_ns(name, attributes, prefix, uri, namespaces)
        on_start_element(name, attributes)
      end

      def on_end_element_ns(name, prefix, uri)
        on_end_element(name)
      end

      def on_error(error)
      end
    end

  end
end

