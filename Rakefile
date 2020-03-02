# frozen_string_literal: true

begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rake'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

# Delegate spec task task to spec:all to run all specs.
task spec: 'spec:all'

desc 'Run all specs'
namespace :spec do
  desc 'Run all msgr specs and all integration specs.'
  task all: %i[unit integration]

  desc 'Run all unit specs.'
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.ruby_opts = '-Ispec/unit'
    t.pattern = 'spec/unit/**/*_spec.rb'
  end

  desc 'Run all integration specs.'
  RSpec::Core::RakeTask.new(:integration) do |t|
    t.ruby_opts = '-Ispec/integration'
    t.pattern = 'spec/integration/**/*_spec.rb'
  end
end

begin
  require 'yard'
  require 'yard/rake/yardoc_task'

  YARD::Rake::YardocTask.new do |t|
    t.files = %w[lib/**/*.rb]
    t.options = %w[--output-dir doc/]
  end
rescue LoadError
  nil
end
