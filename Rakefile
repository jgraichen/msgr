begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rake'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

task 'default' => 'ci'
task 'ci' => 'spec'

desc 'Run all specs'
RSpec::Core::RakeTask.new('spec') do |t|
  t.pattern = 'spec/msgr/**/*_spec.rb'
end
