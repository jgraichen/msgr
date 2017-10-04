# frozen_string_literal: true

source 'https://rubygems.org'

# Development gems
#
gem 'coveralls'
gem 'fuubar'
gem 'rake'
gem 'rspec', '~> 3.0'

group :rails do
  gem 'rails', '>= 3.2' unless $RAILS
  gem 'rspec-rails'
  gem 'sqlite3'
end

# Specify your gem's dependencies in acfs.gemspec
gemroot = File.dirname File.absolute_path __FILE__
gemspec path: gemroot
