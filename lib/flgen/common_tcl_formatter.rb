# frozen_string_literal: true

module FLGen
  class CommonTCLFormatter < Formatter
    def format_header_line(line)
      "#  #{line}"
    end

    def pre_macros(io)
      io.puts('set flgen_defines {}')
    end

    def format_macro(macro, value)
    end

    def post_macros(io)
    end

    def pre_include_directories(io)
      io.puts('set flgen_include_directories {}')
    end

    def format_include_directory(directory)
      "lappend flgen_include_directories \"#{directory}\""
    end

    def post_include_directories(io)
    end

    def pre_source_files(io)
      io.puts('set flgen_source_files {}')
    end

    def format_file_path(path)
      "lappend flgen_source_files \"#{path}\""
    end

    def post_source_files(io)
    end
  end
end
