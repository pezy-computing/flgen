# frozen_string_literal: true

require File.expand_path('lib/file_list_generator/version', __dir__)

Gem::Specification.new do |spec|
  spec.name = 'file_list_generator'
  spec.version = FileListGenerator::VERSION
  spec.authors = ['Taichi Ishitani']
  spec.email = ['ishitani@pezy.co.jp']

  spec.summary = 'File list generator for PEZY environment'
  spec.description = spec.summary
  spec.homepage = 'http://gitlab.pezy.co.jp/pezy/file_list_generator'

  spec.files = `git ls-files exe lib sample README.md`.split($RS)
  spec.bindir = 'exe'
  spec.executables = `git ls-files -- exe/*`.split($RS).map(&File.method(:basename))
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.0'

  spec.add_development_dependency 'bump'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3'
end
