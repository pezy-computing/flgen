# frozen_string_literal: true

module FLGen
  class CadenceTCLFormatter < VivadoTCLFormatter
    def format_macro(macro, value)
      if value.nil?
        "lappend flgen_defines -define #{macro}"
      else
        "lappend flgen_defines -define #{macro}=#{value}"
      end
    end

    def post_macros(io)
      # do nothing
    end

    def post_include_directories(io)
      io.puts("set_db init_hdl_search_path $flgen_include_directories")
    end

    def post_source_files(io)
      io.puts("if {[info exists flgen_defines]} {} else {set flgen_defines {}}")
      io.puts("read_hdl -lib worklib {*}$flgen_defines -sv $flgen_source_files")
    end

    Formatter.add_formatter(:'genus-tcl', self)
  end
end
