# frozen_string_literal: true

module FLGen
  class Context
    def initialize(options)
      @options = options
    end

    attr_reader :options

    def source_files
      @source_files ||= []
    end

    def add_source_file(root, path)
      return if runtime?

      file = SourceFile.new(root, path)
      add_source_file?(file) &&
        (source_files << file.remove_ext(@options[:rm_ext]))
    end

    def define_macro(macro, value = nil)
      k, v =
        if value.nil? && macro.respond_to?(:split)
          macro.split('=', 2)
        else
          [macro, value]
        end
      add_macro_definition(k.to_sym, v)
    end

    def macros
      @macros ||= []
    end

    def add_include_directory(directory)
      return if include_directory_already_added?(directory)
      add_compile_argument(Arguments::Include.new(directory))
    end

    def add_compile_argument(argument)
      return if runtime?
      add_argument(argument)
    end

    def add_runtime_argument(argument)
      return unless runtime?
      add_argument(argument)
    end

    def arguments
      @arguments ||= []
    end

    def loaded_file_lists
      @loaded_file_lists ||= []
    end

    private

    def runtime?
      options[:runtime]
    end

    def add_source_file?(file)
      target_ext?(file) && !source_file_already_added?(file)
    end

    def target_ext?(file)
      return true unless @options.key?(:collect_ext)
      return true if @options[:collect_ext].empty?
      file.match_ext?(@options[:collect_ext])
    end

    def source_file_already_added?(file)
      checksum = file.checksum
      path = file.path

      return true if checksums[path].include?(checksum)

      checksums[path] << checksum
      false
    end

    def checksums
      @checksums ||= Hash.new { |h, k| h[k] = [] }
    end

    def add_macro_definition(name, value)
      macros << name unless macros.include?(name)
      arguments
        .delete_if { |argument| argument.type == :define && argument.name == name }
      add_compile_argument(Arguments::Define.new(name, value))
    end

    def include_directory_already_added?(path)
      arguments
        .any? { |argument| argument.type == :include && argument.path == path }
    end

    def add_argument(argument)
      return unless argument.match_tool?(options[:tool])
      arguments << argument
    end
  end
end