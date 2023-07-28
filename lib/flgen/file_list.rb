# frozen_string_literal: true

module FLGen
  class FileList
    def initialize(context, path)
      @context = context
      @path = path
      @root_directories = extract_root
    end

    def file_list(path, from: :root, raise_error: true)
      location = caller_location
      load_file_list(path, from, location, raise_error)
    end

    def source_file(path, from: :current, raise_error: true)
      location = caller_location
      add_file_entry(path, from, location, raise_error, :add_source_file)
    end

    def library_file(path, from: :current, raise_error: true)
      location = caller_location
      add_file_entry(path, from, location, raise_error, :add_library_file)
    end

    def define_macro(macro, value = nil)
      @context.define_macro(macro, value)
    end

    def macro?(macro)
      @context.macros.include?(macro.to_sym)
    end

    alias_method :macro_defined?, :macro?

    def include_directory(path, from: :current, raise_error: true)
      location = caller_location
      add_directory_entry(path, from, location, raise_error, :add_include_directory)
    end

    def library_directory(path, from: :current, raise_error: true)
      location = caller_location
      add_directory_entry(path, from, location, raise_error, :add_library_directory)
    end

    def file?(path, from: :current)
      location = caller_location
      !extract_file_path(path, from, location).nil?
    end

    def directory?(path, from: :current)
      location = caller_location
      !extract_directory_path(path, from, location).nil?
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
      unless (list_path = extract_file_path(path, from, location))
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

    def add_file_entry(path, from, location, raise_error, method)
      unless (file_path = extract_file_path(path, from, location))
        raise_no_entry_error(path, location, raise_error)
        return
      end

      @context.__send__(method, file_path)
    end

    def add_directory_entry(path, from, location, raise_error, method)
      unless (directory_path = extract_directory_path(path, from, location))
        raise_no_entry_error(path, location, raise_error)
        return
      end

      @context.__send__(method, directory_path)
    end

    def caller_location
      caller_locations(2, 1).first
    end

    def extract_file_path(path, from, location)
      extract_path(path, from, location, :file?)
    end

    def extract_directory_path(path, from, location)
      extract_path(path, from, location, :directory?)
    end

    def extract_path(path, from, location, checker)
      search_root(path, from, location)
        .map { |root| File.expand_path(path, root) }
        .find { |abs_path| File.__send__(checker, abs_path) && abs_path }
    end

    def search_root(path, from, location)
      if absolute_path?(path)
        ['']
      elsif from == :current
        [current_directory(location)]
      elsif from == :local_root
        [@root_directories.last]
      elsif from == :root
        @root_directories
      else
        [from]
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
