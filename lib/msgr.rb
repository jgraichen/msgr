require 'msgr/version'
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/string/inflections'

require 'msgr/client'
require 'msgr/errors'
require 'msgr/route'
require 'msgr/routes'

module Msgr

  class << self
    def logger
      @logger ||= Logger.new $stdout
    end

    def start
      # stub
    end

    def publish
      # stub
    end
  end
end
