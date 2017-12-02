# frozen_string_literal: true

module Fog
  module Parsers
    module Schema
      def reset
        super
        return unless (@schema = self.class.schema)

        @stack = NodeStack.new(@response, @schema, self.class.arrays)
      end

      def start_element(name, attrs = [])
        super
        return unless @schema

        @stack.start_element name
      end

      def end_element(name)
        return super unless @schema

        @stack.end_element name, value
      end

      class NodeStack < Array
        alias_method :top, :last

        def initialize(*args)
          @response, @schema, @arrays = args
          super()
        end

        def start_element(name)
          if top
            if @arrays.include? name
              push top.new_item
            elsif top.next_schema.key? name
              push new_node(name, top.next_schema, top.next_result)
            end
          elsif @schema.key? name
            push new_node(name, @schema, @response)
          end
        end

        def end_element(name, value)
          if top
            if (@arrays + [top.name]).include? name
              top.update_result(value)
              pop
            end
          end
        end

        def new_node(name, schema_pointer, result_pointer)
          node_class =
            case schema_pointer[name]
            when Hash
              NodeHash
            when Array
              NodeArray
            else
              NodeValue
            end
          node_class.new(name, schema_pointer, result_pointer)
        end
      end

      class Node
        attr_reader :name

        def initialize(name, schema_pointer, result_pointer, index = nil)
          @name = name
          @schema_pointer = schema_pointer
          @result_pointer = result_pointer
          @index = index
        end

        def update_result(_value); end

        def next_schema
          raise NotImplementedError
        end

        def next_result
          raise NotImplementedError
        end
      end

      class NodeHash < Node
        def initialize(*_)
          super
          if @index
            @result_pointer[name][@index] = {}
          else
            @result_pointer[name] = {}
          end
        end

        def next_schema
          _next_schema.is_a?(Hash) ? _next_schema : {}
        end

        def next_result
          _next_schema.is_a?(Hash) ? _next_result : {}
        end

        private

        def _next_schema
          if @index
            @schema_pointer[name].first
          else
            @schema_pointer[name]
          end
        end

        def _next_result
          if @index
            @result_pointer[name][@index]
          else
            @result_pointer[name]
          end
        end
      end

      class NodeValue < Node
        def next_schema
          {}
        end

        def next_result
          {}
        end

        def update_result(value)
          if @index
            @result_pointer[name][@index] = cast(value)
          else
            @result_pointer[name] = cast(value)
          end
        end

        private

        def cast(value)
          case @schema_pointer[name]
          when :boolean
            value == "true"
          when :time
            Time.parse(value)
          when :integer
            value.to_i
          when :float
            value.to_f
          else
            value
          end
        end
      end

      class NodeArray < Node
        def initialize(*_)
          super
          @count = 0
          @result_pointer[name] = []
        end

        def next_schema
          @schema_pointer[name].first
        end

        def new_item
          index = @count
          @count += 1
          item_class = next_schema.is_a?(Hash) ? NodeHash : NodeValue
          item_class.new(name, @schema_pointer, @result_pointer, index)
        end
      end
    end
  end
end
