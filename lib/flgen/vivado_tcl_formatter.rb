# frozen_string_literal: true

require_relative 'common_tcl_formatter'

module FLGen
  class VivadoTCLFormatter < CommonTCLFormatter
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

    def post_include_directories(io)
      io.puts('set_property include_dirs $flgen_include_directories [current_fileset]')
    end

    def post_source_files(io)
      io.puts('add_files -fileset [current_fileset] $flgen_source_files')
    end

    Formatter.add_formatter(:'vivado-tcl', self)
  end
end
