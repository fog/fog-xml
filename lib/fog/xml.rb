require 'fog/xml/version'
require 'nokogiri'

module Fog
  module Xml
    autoload :SAXParserConnection, 'fog/xml/sax_parser_connection'
    autoload :Connection, 'fog/xml/connection'
  end
end
