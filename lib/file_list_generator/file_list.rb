# frozen_string_literal: true

module FileListGenerator
  class FileList
    def initialize(context, path)
      @context = context
      @path = path
      @root_directories = extract_root
    end

    def file_list(path, from: :root, raise_error: true)
      root = find_root(path, from, :file?)
      load_file_list(root, path, raise_error)
    end

    def source_file(path, from: :current, raise_error: true)
      root = find_root(path, from, :file?)
      add_source_file(root, path, raise_error)
    end

    def define_macro(macro, value = nil)
      @context.define_macro(macro, value)
    end

    def macro_defined?(macro)
      @context.macros.include?(macro.to_sym)
    end

    def include_directory(path, from: :current, raise_error: true)
      root = find_root(path, from, :directory?)
      add_include_directory(root, path, raise_error)
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

    def find_root(path, from, checker)
      if absolute_path?(path)
        ''
      elsif from == :current
        current_directory
      else
        lookup_root(path, from, checker)
      end
    end

    def absolute_path?(path)
      Pathname.new(path).absolute?
    end

    def current_directory
      # From Ruby 3.1 Thread::Backtrace::Location#absolute_path returns nil
      # for code string evaluated by eval methods
      # see https://github.com/ruby/ruby/commit/64ac984129a7a4645efe5ac57c168ef880b479b2
      location = caller_locations(3, 1).first
      path = location.absolute_path || location.path
      File.dirname(path)
    end

    def lookup_root(path, from, checker)
      (from == :root && @root_directories || [@root_directories.last])
        .find { |root| File.__send__(checker, File.join(root, path)) }
    end

    def load_file_list(root, path, raise_error)
      entry_exist?(root, path, :file?, raise_error) || return

      # Need to File.realpath to resolve symblic link
      list_path = File.realpath(concat_path(root, path))
      file_list_already_loaded?(list_path) && return

      @context.loaded_file_lists << list_path
      self.class.new(@context, list_path)
        .instance_eval(File.read(list_path), list_path)
    end

    def file_list_already_loaded?(path)
      @context.loaded_file_lists.include?(path)
    end

    def add_source_file(root, path, raise_error)
      entry_exist?(root, path, :file?, raise_error) || return
      @context.add_source_file(root, path)
    end

    def add_include_directory(root, path, raise_error)
      entry_exist?(root, path, :directory?, raise_error) || return

      directory_path = concat_path(root, path)
      @context.add_include_directory(directory_path)
    end

    def entry_exist?(root, path, checker, raise_error)
      result = root && File.__send__(checker, concat_path(root, path)) || false
      result ||
        raise_error && (raise NoEntryError.new(path, caller_locations(3, 1)[0]))
    end

    def concat_path(root, path)
      File.expand_path(path, root)
    end
  end
end
