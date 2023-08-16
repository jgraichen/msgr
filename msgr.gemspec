# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'msgr/version'

Gem::Specification.new do |spec|
  spec.name          = 'msgr'
  spec.version       = Msgr::VERSION
  spec.authors       = ['Jan Graichen']
  spec.email         = ['jgraichen@altimos.de']
  spec.description   = 'Msgr: Rails-like Messaging Framework'
  spec.summary       = 'Msgr: Rails-like Messaging Framework'
  spec.homepage      = 'https://github.com/jgraichen/msgr'
  spec.license       = 'MIT'

  spec.metadata = {
    'rubygems_mfa_required' => 'true',
  }

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) {|f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w[lib]

  spec.required_ruby_version = '>= 2.5'

  spec.add_dependency 'activesupport'
  spec.add_dependency 'bunny', '>= 1.4', '< 3.0'
end
