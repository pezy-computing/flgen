# frozen_string_literal: true

require File.expand_path('lib/flgen/version', __dir__)

Gem::Specification.new do |spec|
  spec.name = 'flgen'
  spec.version = FLGen::VERSION
  spec.authors = ['Taichi Ishitani']
  spec.email = ['ishitani@pezy.co.jp']

  spec.summary = 'Filelist generator'
  spec.description = spec.summary
  spec.homepage = 'https://github.com/pezy-computing/flgen'
  spec.license = 'Apache-2.0'

  spec.files = `git ls-files exe lib sample README.md LICENSE`.split($RS)
  spec.bindir = 'exe'
  spec.executables = `git ls-files -- exe/*`.split($RS).map(&File.method(:basename))
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.0'

  spec.add_development_dependency 'bump'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3'
end
