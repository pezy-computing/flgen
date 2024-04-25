# frozen_string_literal: true

require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

CLEAN << 'coverage'

RSpec::Core::RakeTask.new(:spec)

unless ENV.key?('CI')
  require 'bump/tasks'
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop)
end

desc 'Run all RSpec code exmaples and collect code coverage'
task :coverage do
  ENV['COVERAGE'] = 'yes'
  Rake::Task['spec'].execute
end

task default: :spec
