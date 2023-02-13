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
      print_library_direcotries(io)
      print_library_files(io)
      print_arguments(io)
      print_source_files(io)
    end

    private

    def print_header(io)
      return unless print_header?

      header_lines.each do |line|
        print_value(io, :format_header_line, line)
      end
    end

    def format_header_line(_line)
    end

    def print_header?
      @context.options[:output] &&
        @context.options[:print_header] && !@context.options[:source_file_only]
    end

    def print_macros(io)
      return if source_file_only? || no_arguments?(:define)

      pre_macros(io)
      each_argument(:define) do |argument|
        print_value(io, :format_macro, argument.name, argument.value)
      end
      post_macros(io)
    end

    def pre_macros(_io)
    end

    def format_macro(_name, _value)
    end

    def post_macros(_io)
    end

    def print_include_directoris(io)
      return if source_file_only? || no_arguments?(:include)

      pre_include_directories(io)
      each_argument(:include) do |argument|
        print_value(io, :format_include_directory, argument.path)
      end
      post_include_directories(io)
    end

    def pre_include_directories(_io)
    end

    def format_include_directory(_path)
    end

    def post_include_directories(_io)
    end

    def print_library_direcotries(io)
      return if source_file_only? || no_arguments?(:library_directory)

      pre_library_direcotries(io)
      each_argument(:library_directory) do |argument|
        print_value(io, :format_libarary_directory, argument.path)
      end
      post_library_direcotries(io)
    end

    def pre_library_direcotries(_io)
    end

    def format_libarary_directory(_path)
    end

    def post_library_direcotries(_io)
    end

    def print_library_files(io)
      return if source_file_only? || no_arguments?(:library_file)

      pre_library_files(io)
      each_argument(:library_file) do |argument|
        print_value(io, :format_libarary_file, argument.path)
      end
      post_library_files(io)
    end

    def pre_library_files(_io)
    end

    def format_libarary_file(_path)
    end

    def post_library_files(_io)
    end

    def print_arguments(io)
      return if source_file_only? || no_arguments?(:generic)

      pre_arguments(io)
      each_argument(:generic) do |argument|
        print_value(io, :fomrat_argument, argument.argument)
      end
      post_arguments(io)
    end

    def pre_arguments(io)
    end

    def fomrat_argument(_argument)
    end

    def post_arguments(io)
    end

    def source_file_only?
      @context.options[:source_file_only]
    end

    def print_source_files(io)
      return if no_source_files?

      pre_source_files(io)
      @context.source_files.each do |file|
        print_value(io, :format_file_path, file)
      end
      post_source_files(io)
    end

    def no_source_files?
      @context.source_files.empty?
    end

    def pre_source_files(_io)
    end

    def format_file_path(_path)
    end

    def post_source_files(_io)
    end

    def print_value(io, fomrtatter, *args)
      line = __send__(fomrtatter, *args)
      line && io.puts(line)
    end

    def no_arguments?(type)
      @context.arguments.none? { |argument| argument.type == type }
    end

    def each_argument(type, &block)
      @context.arguments.each do |argument|
        argument.type == type && block.call(argument)
      end
    end
  end
end
