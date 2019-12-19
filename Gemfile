# frozen_string_literal: true

source 'https://rubygems.org'

group :development, :test do
  gem 'coveralls'
  gem 'fuubar'
  gem 'rake'
  gem 'rspec', '~> 3.0'
  gem 'rubocop', '~> 0.78.0'
end

group :rails do
  unless defined?(NO_RAILS_GEM)
    gem 'rails', '>= 4.2'
    gem 'sqlite3'
  end

  gem 'rspec-rails', require: false
end

# Specify your gem's dependencies in acfs.gemspec
gemspec
