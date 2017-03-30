# frozen_string_literal: true
require 'bundler'

# Somewhere between
#   `ruby -w -W2 -S rspec ...`
# and the rspec executable `bundle/setup` is required or
# `Bundler.setup` without groups called. This will let Bundler
# load ALL gems from ALL groups. This results in leaking
# gems only for rails integration tests into msgr testing
# environment.
#
# This file will be required by ruby on the commandline before
# everything else can kick in. The code snippet below will
# patch bundler to just ignore `setup` calls without
# specified groups. All test helper will explicit call
# `Bundler.setup` with required test groups.

module Bundler
  class << self
    alias old_setup setup
    def setup(*groups)
      old_setup(*groups) unless groups.empty?
    end
  end
end

# Only load default group
Bundler.setup :default
