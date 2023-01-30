# frozen_string_literal: true

module FLGen
  class SourceFile
    def initialize(root, path)
      @path = File.join(root, path)
    end

    attr_reader :path

    def match_ext?(ext_list)
      return false if ext_list.nil? || ext_list.empty?

      file_ext = File.extname(@path)[1..]
      ext_list.any? { |ext| (ext[0] == '.' && ext[1..] || ext) == file_ext }
    end

    def remove_ext(ext_list)
      return self unless match_ext?(ext_list)

      path = Pathname.new(@path).sub_ext('').to_s
      self.class.new('', path)
    end

    def checksum
      @checksum ||= Digest::MD5.digest(File.read(@path))
    end
  end
end
