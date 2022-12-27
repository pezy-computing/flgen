# frozen_string_literal: true

module FLGen
  class FileListXsimFormatter < Formatter
    def format_header_line(line)
      "//  #{line}"
    end

    def format_macro(macro, value)
      if value.nil?
        "-d #{macro}"
      else
        "-d #{macro}=#{value}"
      end
    end

    def format_include_directory(directory)
      "-i #{directory}"
    end

    def fomrat_argument(argument)
      argument
    end

    def format_file_path(path)
      path
    end

    Formatter.add_formatter(:'filelist-xsim', self)
  end
end
