# frozen_string_literal: true

module FLGen
  class FileList
    def initialize(context, path)
      @context = context
      @path = path
      @root_directories = extract_root
      @default_search_path = init_default_search_path
    end

    def default_search_path(**search_paths)
      @default_search_path.update(search_paths)
    end

    def reset_default_search_path(*target_types)
      target_types.each { |type| @default_search_path.delete(type) }
    end

    def file_list(path, from: nil, raise_error: true)
      load_file_list(path, from, raise_error, caller_location)
    end

    def source_file(path, from: nil, raise_error: true)
      add_entry(path, from, raise_error, __callee__, caller_location)
    end

    define_method(:library_file, instance_method(:source_file))
    define_method(:include_directory, instance_method(:source_file))
    define_method(:library_directory, instance_method(:source_file))

    def find_files(patterns, from: nil, &block)
      glob_files(patterns, from, __callee__, caller_location)
        .then { |e| block ? e.each(&block) : e.to_a }
    end

    def find_file(patterns, from: nil)
      glob_files(patterns, from, __callee__, caller_location).first
    end

    def file?(path, from: :current)
      !extract_path(path, from, __callee__, caller_location).nil?
    end

    define_method(:directory?, instance_method(:file?))

    def define_macro(macro, value = nil)
      @context.define_macro(macro, value)
    end

    def macro?(macro)
      @context.macros.include?(macro.to_sym)
    end

    alias_method :macro_defined?, :macro?

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
        .new(@path).dirname.descend.select(&method(:repository_root?)).map(&:to_s)
    end

    def repository_root?(path)
      File.exist?(path.join('.git').to_s)
    end

    def init_default_search_path
      Hash.new { |_, key| key == :file_list ? :root : :current }
    end

    def load_file_list(path, from, raise_error, location)
      unless (extracted_path = extract_path(path, from, :file_list, location))
        raise_no_entry_error(path, location, raise_error)
        return
      end

      # Need to File.realpath to resolve symblic link
      list_path = File.realpath(extracted_path)
      file_list_already_loaded?(list_path) && return

      @context.loaded_file_lists << list_path
      self.class.new(@context, list_path)
        .instance_eval(File.read(list_path), list_path)
    end

    def file_list_already_loaded?(path)
      @context.loaded_file_lists.include?(path)
    end

    def add_entry(path, from, raise_error, method_name, location)
      unless (extracted_path = extract_path(path, from, method_name, location))
        raise_no_entry_error(path, location, raise_error)
        return
      end

      @context.__send__("add_#{method_name}", extracted_path)
    end

    def raise_no_entry_error(path, location, raise_error)
      return unless raise_error

      raise NoEntryError.new(path, location)
    end

    def glob_files(patterns, from, method_name, location)
      search_root('', from, method_name, location)
        .lazy.flat_map { |base| do_glob_files(patterns, base) }
    end

    def do_glob_files(patterns, base)
      Dir.glob(Array(patterns), base: base)
        .map { |path| File.join(base, path) }
        .select(&File.method(:file?))
    end

    def caller_location
      caller_locations(2, 1).first
    end

    def extract_path(path, from, method_name, location)
      search_root(path, from, method_name, location)
        .map { |root| File.expand_path(path, root) }
        .find { |abs_path| exist_path?(abs_path, method_name) }
    end

    FROM_KEYWORDS = [:cwd, :current, :local_root, :root].freeze

    def search_root(path, from, method_name, location)
      search_path = from || @default_search_path[method_name]
      if absolute_path?(path)
        ['']
      elsif FROM_KEYWORDS.include?(search_path)
        search_root_specified_by_keyword(search_path, location)
      else
        [search_path]
      end
    end

    def absolute_path?(path)
      Pathname.new(path).absolute?
    end

    def search_root_specified_by_keyword(from_keyword, location)
      case from_keyword
      when :cwd then [Dir.pwd]
      when :current then [current_directory(location)]
      when :local_root then [@root_directories.last]
      else @root_directories
      end
    end

    def current_directory(location)
      # From Ruby 3.1 Thread::Backtrace::Location#absolute_path returns nil
      # for code string evaluated by eval methods
      # see https://github.com/ruby/ruby/commit/64ac984129a7a4645efe5ac57c168ef880b479b2
      path = location.absolute_path || location.path
      File.dirname(path)
    end

    METHODS_TARGETING_DIRECTORY =
      [:include_directory, :library_directory, :directory?].freeze

    def exist_path?(path, method_name)
      if METHODS_TARGETING_DIRECTORY.include?(method_name)
        File.directory?(path)
      else
        File.file?(path)
      end
    end
  end
end
