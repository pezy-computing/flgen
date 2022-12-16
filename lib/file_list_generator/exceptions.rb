# frozen_string_literal: true

module FileListGenerator
  class FileListGeneratorError < StandardError
  end

  class NoEntryError < FileListGeneratorError
    def initialize(path, location)
      message =
        "no such file or directory -- #{path} " \
        "@#{location.path}:#{location.lineno}"
      super(message)
    end
  end
end
