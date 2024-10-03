# frozen_string_literal: true

# Bundler setup
require 'bundler'
Bundler.setup :default, :test

require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.start do
  command_name 'rspec:unit'
  add_filter 'spec'

  self.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter,
  ]
end

require 'msgr'

Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each {|f| require f }

RSpec.configure do |config|
  config.order = 'random'
  config.expect_with :rspec do |c|
    # Only allow expect syntax
    c.syntax = :expect
  end
end
