# frozen_string_literal: true

module FLGen
  class Formatter
    class << self
      def add_formatter(type, formatter)
        formatters[type] = formatter
      end

      def formatters
        @formatters ||= {}
      end
    end

    def initialize(context)
      @context = context
      @header_lines = []
    end

    attr_reader :header_lines

    def output(io)
      print_header(io)
      print_macros(io)
      print_include_directoris(io)
      print_arguments(io)
      print_source_files(io)
    end

    private

    def print_header(io)
      return unless print_header?

      header_lines.each do |line|
        io.puts(format_header_line(line))
      end
    end

    def print_header?
      @context.options[:output] &&
        @context.options[:print_header] && !@context.options[:source_file_only]
    end

    def each_argument(type, &block)
      @context.arguments.each do |argument|
        argument.type == type && block.call(argument)
      end
    end

    def print_macros(io)
      return if source_file_only?

      pre_macros(io)
      each_argument(:define) do |argument|
        io.puts(format_macro(argument.name, argument.value))
      end
      post_macros(io)
    end

    def pre_macros(_io)
    end

    def post_macros(_io)
    end

    def print_include_directoris(io)
      return if source_file_only?

      pre_include_directories(io)
      each_argument(:include) do |argument|
        io.puts(format_include_directory(argument.path))
      end
      post_include_directories(io)
    end

    def pre_include_directories(_io)
    end

    def post_include_directories(_io)
    end

    def print_arguments(io)
      return if source_file_only?

      pre_arguments(io)
      each_argument(:generic) do |argument|
        io.puts(fomrat_argument(argument.argument))
      end
      post_arguments(io)
    end

    def pre_arguments(io)
    end

    def post_arguments(io)
    end

    def source_file_only?
      @context.options[:source_file_only]
    end

    def print_source_files(io)
      pre_source_files(io)
      @context.source_files.each do |file|
        io.puts(format_file_path(file.full_path))
      end
      post_source_files(io)
    end

    def pre_source_files(_io)
    end

    def post_source_files(_io)
    end
  end
end
