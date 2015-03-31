require "nokogiri"
require "saxxy/callbacks/sax"


module Saxxy
  module Callbacks

    class Nokogiri < Nokogiri::XML::SAX::Document
      include SAX

      def start_element(name, attrs)
        on_start_element(name, Hash[attrs])
      end

      def characters(string)
        on_characters(string)
      end

      def end_element(name)
        on_end_element(name)
      end

      def end_document
        on_end_document
      end
    end

  end
end

