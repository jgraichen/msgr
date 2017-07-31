# frozen_string_literal: true

source 'https://rubygems.org'

# Development gems
#
gem 'coveralls'
gem 'fuubar'
gem 'rake'
gem 'rspec', '~> 3.0'

# Doc
group :development do
  gem 'guard-rspec'
  gem 'guard-yard'
  gem 'listen'
  gem 'redcarpet'
  gem 'yard', '~> 0.9.8'
end

group :rails do
  gem 'rails', '>= 3.2' unless $RAILS
  gem 'rspec-rails'
  gem 'sqlite3'
end

# Specify your gem's dependencies in acfs.gemspec
gemroot = File.dirname File.absolute_path __FILE__
gemspec path: gemroot
