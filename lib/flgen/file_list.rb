# frozen_string_literal: true

module FLGen
  class FileList
    def initialize(context, path)
      @context = context
      @path = path
      @root_directories = extract_root
      @default_search_path = {}
    end

    def default_search_path(**seach_paths)
      @default_search_path.update(seach_paths)
    end

    def reset_default_search_path(*target_types)
      target_types.each { |type| @default_search_path.delete(type) }
    end

    def file_list(path, from: nil, raise_error: true)
      location = caller_location
      load_file_list(path, from, location, raise_error)
    end

    def source_file(path, from: nil, raise_error: true)
      location = caller_location
      add_file_entry(path, from, location, raise_error, :source_file)
    end

    def library_file(path, from: nil, raise_error: true)
      location = caller_location
      add_file_entry(path, from, location, raise_error, :library_file)
    end

    def define_macro(macro, value = nil)
      @context.define_macro(macro, value)
    end

    def macro?(macro)
      @context.macros.include?(macro.to_sym)
    end

    alias_method :macro_defined?, :macro?

    def include_directory(path, from: nil, raise_error: true)
      location = caller_location
      add_directory_entry(path, from, location, raise_error, :include_directory)
    end

    def library_directory(path, from: nil, raise_error: true)
      location = caller_location
      add_directory_entry(path, from, location, raise_error, :library_directory)
    end

    def file?(path, from: :current)
      location = caller_location
      !extract_file_path(path, from, location, :file).nil?
    end

    def directory?(path, from: :current)
      location = caller_location
      !extract_directory_path(path, from, location, :directory).nil?
    end

    def env?(name)
      ENV.key?(name.to_s)
    end

    def env(name)
      ENV.fetch(name.to_s, nil)
    end

    def target_tool?(tool)
      target_tool = @context.options[:tool]
      target_tool && tool.to_sym == target_tool || false
    end

    def compile_argument(argument, tool: nil)
      @context.add_compile_argument(Arguments::Generic.new(argument, tool))
    end

    def runtime_argument(argument, tool: nil)
      @context.add_runtime_argument(Arguments::Generic.new(argument, tool))
    end

    private

    def extract_root
      return nil if @path.empty?

      Pathname
        .new(@path)
        .dirname
        .descend
        .select(&method(:repository_root?))
        .map(&:to_s)
    end

    def repository_root?(path)
      File.exist?(path.join('.git').to_s)
    end

    def load_file_list(path, from, location, raise_error)
      unless (list_path = extract_file_path(path, from, location, :file_list))
        raise_no_entry_error(path, location, raise_error)
        return
      end

      # Need to File.realpath to resolve symblic link
      list_path = File.realpath(list_path)
      file_list_already_loaded?(list_path) && return

      @context.loaded_file_lists << list_path
      self.class.new(@context, list_path)
        .instance_eval(File.read(list_path), list_path)
    end

    def file_list_already_loaded?(path)
      @context.loaded_file_lists.include?(path)
    end

    def add_file_entry(path, from, location, raise_error, type)
      unless (file_path = extract_file_path(path, from, location, type))
        raise_no_entry_error(path, location, raise_error)
        return
      end

      method = "add_#{type}".to_sym
      @context.__send__(method, file_path)
    end

    def add_directory_entry(path, from, location, raise_error, type)
      unless (directory_path = extract_directory_path(path, from, location, type))
        raise_no_entry_error(path, location, raise_error)
        return
      end

      method = "add_#{type}".to_sym
      @context.__send__(method, directory_path)
    end

    def caller_location
      caller_locations(2, 1).first
    end

    def extract_file_path(path, from, location, type)
      extract_path(path, from, location, type, :file?)
    end

    def extract_directory_path(path, from, location, type)
      extract_path(path, from, location, type, :directory?)
    end

    def extract_path(path, from, location, type, checker)
      search_root(path, from, location, type)
        .map { |root| File.expand_path(path, root) }
        .find { |abs_path| File.__send__(checker, abs_path) && abs_path }
    end

    DEFAULT_SEARCH_PATH = {
      file_list: :root, source_file: :current, library_file: :current, file: :current,
      include_directory: :current, library_directory: :current, directory: :current
    }.freeze

    def search_root(path, from, location, type)
      search_path = from || @default_search_path[type] || DEFAULT_SEARCH_PATH[type]
      if absolute_path?(path)
        ['']
      elsif search_path == :current
        [current_directory(location)]
      elsif search_path == :local_root
        [@root_directories.last]
      elsif search_path == :root
        @root_directories
      else
        [search_path]
      end
    end

    def absolute_path?(path)
      Pathname.new(path).absolute?
    end

    def current_directory(location)
      # From Ruby 3.1 Thread::Backtrace::Location#absolute_path returns nil
      # for code string evaluated by eval methods
      # see https://github.com/ruby/ruby/commit/64ac984129a7a4645efe5ac57c168ef880b479b2
      path = location.absolute_path || location.path
      File.dirname(path)
    end

    def raise_no_entry_error(path, location, raise_error)
      return unless raise_error

      raise NoEntryError.new(path, location)
    end
  end
end
