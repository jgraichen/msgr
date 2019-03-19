# frozen_string_literal: true

source 'https://rubygems.org'

group :development, :test do
  gem 'coveralls'
  gem 'fuubar'
  gem 'rake'
  gem 'rspec', '~> 3.0'
  gem 'rubocop', '~> 0.50.0'
end

group :rails do
  gem 'rails', '>= 4.2' unless defined?(NO_RAILS_GEM)
  gem 'rspec-rails', require: false
  gem 'sqlite3', '~> 1.4.0'
end

# Specify your gem's dependencies in acfs.gemspec
gemspec
