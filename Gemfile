source 'https://rubygems.org'

# Development gems
#
gem 'rake'
gem 'rspec', '~> 3.0'
gem 'fuubar'
gem 'coveralls'

# Doc
group :development do
  gem 'yard', '~> 0.9.8'
  gem 'listen'
  gem 'guard-yard'
  gem 'guard-rspec'
  gem 'redcarpet', platform: :ruby
end

group :rails do
  gem 'rails', '>= 3.2'
  gem 'rspec-rails'
  gem 'sqlite3', platform: :ruby
  gem 'activerecord-jdbcsqlite3-adapter', platform: :jruby
end

platform :rbx do
  gem 'rubysl'
  gem 'rubinius-coverage'
  gem 'racc'
end

# Specify your gem's dependencies in acfs.gemspec
gemroot = File.dirname File.absolute_path __FILE__
gemspec path: gemroot
