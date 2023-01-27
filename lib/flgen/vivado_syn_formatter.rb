# frozen_string_literal: true

module FLGen
  class VivadoSynFormatter < Formatter
    def format_header_line(line)
      "#  #{line}"
    end

    def pre_macros(io)
      io.puts('set flgen_defines {}')
    end

    def format_macro(macro, value)
      if value.nil?
        "lappend flgen_defines \"#{macro}\""
      else
        "lappend flgen_defines \"#{macro}=#{value}\""
      end
    end

    def post_macros(io)
      io.puts('set_property verilog_define $flgen_defines [current_fileset]')
    end

    def pre_include_directories(io)
      io.puts('set flgen_include_directories {}')
    end

    def format_include_directory(directory)
      "lappend flgen_include_directories \"#{directory}\""
    end

    def post_include_directories(io)
      io.puts('set_property include_dirs $flgen_include_directories [current_fileset]')
    end

    def fomrat_argument(_)
    end

    def pre_source_files(io)
      io.puts('set flgen_source_files {}')
    end

    def format_file_path(path)
      "lappend flgen_source_files \"#{path}\""
    end

    def post_source_files(io)
      io.puts('add_files -fileset [current_fileset] $flgen_source_files')
    end

    Formatter.add_formatter(:'vivado-syn', self)
  end
end
