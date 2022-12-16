# frozen_string_literal: true

module FLGen
  class SourceFile
    def initialize(root, path)
      @root = root
      @path = path
    end

    attr_reader :root
    attr_reader :path

    def full_path
      File.join(@root, @path)
    end

    def match_ext?(ext_list)
      return false if ext_list.nil? || ext_list.empty?

      file_ext = File.extname(@path)
      ext_list.any? do |ext|
        (ext[0] == '.' && ext || ".#{ext}") == file_ext
      end
    end

    def remove_ext(ext_list)
      return self unless match_ext?(ext_list)
      path = Pathname.new(@path).sub_ext('').to_s
      self.class.new(@root, path)
    end

    def checksum
      @checksum ||= Digest::MD5.digest(File.read(full_path))
    end
  end
end
