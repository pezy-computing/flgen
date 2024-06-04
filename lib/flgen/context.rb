# frozen_string_literal: true

module FLGen
  class Context
    def initialize(options)
      @options = options
      define_predefined_macros
    end

    attr_reader :options

    def source_files
      @source_files ||= []
    end

    def add_source_file(path)
      return if runtime?

      file = SourceFile.new(path)
      add_source_file?(file) &&
        (source_files << file.remove_ext(@options[:rm_ext]))
    end

    def add_library_file(path)
      return if runtime?

      file = SourceFile.new(path)
      add_library_file?(file) &&
        add_compile_argument(Arguments::LibraryFile.new(file))
    end

    def define_macro(macro, value = nil)
      k, v =
        if value.nil? && macro.respond_to?(:split)
          macro.split('=', 2)
        else
          [macro, value]
        end
      add_macro_definition(k, v, false)
    end

    def undefine_macro(macro)
      remove_macro(macro)
    end

    def macros
      @macros ||= {}
    end

    def add_include_directory(directory)
      return if directory_already_added?(:include, directory)

      add_compile_argument(Arguments::Include.new(directory))
    end

    def add_library_directory(directory)
      return if directory_already_added?(:library_directory, directory)

      add_compile_argument(Arguments::LibraryDirectory.new(directory))
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
      target_ext?(file) && source_files.none?(file)
    end

    def target_ext?(file)
      return true unless @options.key?(:collect_ext)
      return true if @options[:collect_ext].empty?

      file.match_ext?(@options[:collect_ext])
    end

    def add_library_file?(file)
      arguments.none? { |arg| arg.type == :library_file && arg.path == file }
    end

    def define_predefined_macros
      return unless options[:tool]

      list_name = File.join(__dir__, 'predefined_macros.yaml')
      list = YAML.safe_load_file(list_name, filename: list_name, symbolize_names: true)
      list[options[:tool]]&.each { |macro| add_macro_definition(macro, nil, true) }
    end

    def add_macro_definition(macro, value, predefined)
      name = macro.to_sym
      macros[name] = value || true
      add_macro_argument(name, value) unless predefined
    end

    def add_macro_argument(name, value)
      arguments.delete_if { |arg| macro_definition?(arg, name) }
      add_compile_argument(Arguments::Define.new(name, value))
    end

    def remove_macro(macro)
      name = macro.to_sym
      arguments.reject! { |arg| macro_definition?(arg, name) } && macros.delete(name)
    end

    def macro_definition?(arg, name)
      arg.type == :define && arg.name == name
    end

    def directory_already_added?(type, path)
      arguments
        .any? { |argument| argument.type == type && argument.path == path }
    end

    def add_argument(argument)
      return unless argument.match_tool?(options[:tool])

      arguments << argument
    end
  end
end
