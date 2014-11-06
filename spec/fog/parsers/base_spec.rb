require "minitest_helper"

describe Fog::Parsers::Base do
  
  def parse(input, parser_class)
    document = parser_class.new
    parser = Nokogiri::XML::SAX::Parser.new(document)
    parser.parse input
    document.response
  end

  describe 'value' do
    class ValueTest < Fog::Parsers::Base

      def start_element(name, attrs)
        @stack.push({})
        super
      end

      def reset
        super
        @stack = [@response]
      end

      def end_element name
        top = @stack.pop
        if top.empty?
          @stack.last[name] = value
        else
          @stack.last[name] = top if @stack.any?
        end
      end

    end

    it 'extracts the characters for the current element' do
      doc = <<-XML
      <Test>
        <Foo>FooValue</Foo>
        <Bar>BarValue</Bar>
      </Test>
      XML
      assert_equal({'Test'=> {'Foo' => 'FooValue', 'Bar' => 'BarValue'}}, parse(doc, ValueTest))
    end
  end
end