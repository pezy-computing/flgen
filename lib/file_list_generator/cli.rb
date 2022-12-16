# frozen_string_literal: true

module FileListGenerator
  class CLI
    PROGRAM_NAME = 'flgen'

    def run(args)
      options, remain_args = parse_options(args.dup)
      context = parse_file_list(options, remain_args)
      output_result(args, context)
    end

    private

    def parse_options(args)
      options = {
        macros: [], include_directories: [], runtime: false, tool: nil,
        rm_ext: [], collect_ext: [], format: :filelist, print_header: true,
        source_file_only: false
      }
      option_parser(options).parse!(args)
      [options, args]
    end

    def option_parser(options)
      OptionParser.new do |parser|
        parser.version = VERSION
        parser.program_name = PROGRAM_NAME

        parser.on('--define-macro=MACRO[,MACRO]', Array) do |macros|
          options[:macros].concat(macros)
        end
        parser.on('--include-directory=DIR[,DIR]', Array) do |directories|
          options[:include_directories].concat(directories)
        end
        parser.on('--compile') do
          options[:runtime] = false
        end
        parser.on('--runtime') do
          options[:runtime] = true
        end
        parser.on('--tool=TOOL') do |tool|
          options[:tool] = tool.to_sym
        end
        parser.on('--rm-ext=EXT[,EXT]', Array) do |ext|
          options[:rm_ext].concat(ext)
        end
        parser.on('--collect-ext=EXT[,EXT]', Array) do |ext|
          options[:collect_ext].concat(ext)
        end
        parser.on('--format=FORMAT') do |format|
          options[:format] = format.to_sym
        end
        parser.on('--output=FILE') do |file|
          options[:output] = file
        end
        parser.on('--[no-]print-header') do |value|
          options[:print_header] = value
        end
        parser.on('--source-file-only') do |value|
          options[:source_file_only] = value
        end
      end
    end

    def parse_file_list(options, args)
      context = create_context(options)
      top_level = FileList.new(context, '')
      args.each { |arg| load_file_list(top_level, arg) }
      context
    end

    def create_context(options)
      context = Context.new(options)
      context
        .options[:macros]
        .each(&context.method(:define_macro))
      context
        .options[:include_directories]
        .each(&context.method(:add_include_directory))
      context
    end

    def load_file_list(top_level, arg)
      path = File.expand_path(arg)
      top_level.file_list(path)
    end

    def output_result(args, context)
      formatter = create_formatter(context)
      print_header(context, formatter, args)
      if context.options[:output]
        File.open(context.options[:output], 'w') { |io| formatter.output(io) }
      else
        formatter.output($stdout)
      end
    end

    def create_formatter(context)
      formatter = Formatter.formatters[context.options[:format]]
      formatter.new(context)
    end

    def print_header(context, formatter, args)
      formatter.header_lines << "#{PROGRAM_NAME} version #{FileListGenerator::VERSION}"
      formatter.header_lines << 'applied arguments'
      args.each do |arg|
        formatter.header_lines << "  #{arg}"
      end
    end
  end
end
