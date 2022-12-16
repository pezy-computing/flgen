# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'bump/tasks'

RSpec::Core::RakeTask.new(:rspec)
RuboCop::RakeTask.new(:rubocop)

desc 'Run all RSpec code exmaples and collect code coverage'
task :coverage do
  ENV['COVERAGE'] = 'yes'
  Rake::Task['rspec'].execute
end

task default: :rspec
