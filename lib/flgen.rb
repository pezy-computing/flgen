# frozen_string_literal: true

require 'digest/md5'
require 'optparse'
require 'pathname'
require_relative 'flgen/version'
require_relative 'flgen/exceptions'
require_relative 'flgen/source_file'
require_relative 'flgen/arguments'
require_relative 'flgen/file_list'
require_relative 'flgen/context'
require_relative 'flgen/formatter'
require_relative 'flgen/file_list_formatter'
require_relative 'flgen/cli'