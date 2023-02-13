# frozen_string_literal: true

module FLGen
  class SourceFile
    def initialize(root, path, checksum = nil)
      @path = File.join(root, path)
      @checksum = checksum
    end

    attr_reader :path
    alias_method :to_s, :path

    def ==(other)
      case other
      when SourceFile then path == other.path || checksum == other.checksum
      else path == other
      end
    end

    def match_ext?(ext_list)
      return false if ext_list.nil? || ext_list.empty?

      file_ext = File.extname(@path)[1..]
      ext_list.any? { |ext| (ext[0] == '.' && ext[1..] || ext) == file_ext }
    end

    def remove_ext(ext_list)
      return self unless match_ext?(ext_list)

      path = Pathname.new(@path).sub_ext('').to_s
      self.class.new('', path, checksum)
    end

    def checksum
      @checksum ||= Digest::MD5.digest(File.read(@path))
    end
  end
end
