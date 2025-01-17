# frozen_string_literal: true

# Bundler setup
require 'bundler'
Bundler.require :rails, :test

require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.start do
  command_name 'rspec:integration'
  add_filter 'spec'

  self.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter,
  ]
end

ENV['RAILS_ENV'] ||= 'test'
ENV['RAILS_GROUPS'] = ['rails', ENV.fetch('RAILS_GROUPS', nil)].compact.join(',')
require File.expand_path('dummy/config/environment', __dir__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.expand_path('support/**/*.rb', __dir__)].each {|f| require f }

if ActiveRecord::Migration.respond_to?(:check_all_pending!)
  ActiveRecord::Migration.check_all_pending!
else
  ActiveRecord::Migration.check_pending!
end

RSpec.configure do |config|
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.expect_with :rspec do |c|
    # Only allow expect syntax
    c.syntax = :expect
  end

  config.after do
    # Flush the consumer queue
    Msgr.client.stop delete: true
    Msgr::TestPool.reset
  end
end
