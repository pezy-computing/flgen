# frozen_string_literal: true

module FLGen
  class FLGenError < StandardError
  end

  class NoEntryError < FLGenError
    def initialize(path, location)
      message =
        "no such file or directory -- #{path} " \
        "@#{location.path}:#{location.lineno}"
      super(message)
    end
  end
end
