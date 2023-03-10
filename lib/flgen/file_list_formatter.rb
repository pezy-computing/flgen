# frozen_string_literal: true

module FLGen
  class FileListFormatter < Formatter
    def format_header_line(line)
      "//  #{line}"
    end

    def format_macro(macro, value)
      if value.nil?
        "+define+#{macro}"
      else
        "+define+#{macro}=#{value}"
      end
    end

    def format_include_directory(directory)
      "+incdir+#{directory}"
    end

    def format_libarary_directory(directory)
      "-y #{directory}"
    end

    def format_libarary_file(file)
      "-v #{file}"
    end

    def fomrat_argument(argument)
      argument
    end

    def format_file_path(path)
      path
    end

    Formatter.add_formatter(:filelist, self)
  end
end
