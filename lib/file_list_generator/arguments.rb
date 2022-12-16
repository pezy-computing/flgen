# frozen_string_literal: true

module FileListGenerator
  module Arguments
    class Base
      def initialize(type, tool)
        @type = type
        @tool = tool
      end

      attr_reader :type
      attr_reader :tool

      def match_tool?(target_tool)
        tool.nil? || target_tool && (tool == target_tool) || false
      end
    end

    class Define < Base
      def initialize(name, value)
        super(:define, nil)
        @name = name
        @value = value
      end

      attr_reader :name
      attr_reader :value
    end

    class Include < Base
      def initialize(path)
        super(:include, nil)
        @path = path
      end

      attr_reader :path
    end

    class Generic < Base
      def initialize(argument, tool)
        super(:generic, tool)
        @argument = argument
      end

      attr_reader :argument
    end
  end
end
