# frozen_string_literal: true

source 'https://rubygems.org'

group :development, :test do
  gem 'coveralls'
  gem 'fuubar'
  gem 'rake'
  gem 'rspec', '~> 3.0'
  gem 'rubocop', '~> 0.65.0'
end

group :rails do
  gem 'rails', '>= 4.2' unless defined?(NO_RAILS_GEM)
  gem 'rspec-rails', require: false
  gem 'sqlite3'
end

# Specify your gem's dependencies in acfs.gemspec
gemroot = File.dirname File.absolute_path __FILE__
gemspec path: gemroot
