begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rake'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

task 'default' => 'ci'

desc 'Run all specs'
task 'spec' => 'spec:all'

namespace 'spec' do
  task 'all' => ['msgr']

  desc 'Run msgr specs'
  RSpec::Core::RakeTask.new('msgr') do |t|
    t.pattern = 'spec/msgr/**/*_spec.rb'
  end
end
