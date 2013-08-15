require 'msgr/version'
require 'celluloid'
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/string/inflections'

require 'msgr/logging'
require 'msgr/binding'
require 'msgr/client'
require 'msgr/connection'
require 'msgr/dispatcher'
require 'msgr/errors'
require 'msgr/message'
require 'msgr/pool'
require 'msgr/route'
require 'msgr/routes'

module Msgr

  class << self
    def logger
      @logger ||= Logger.new($stdout).tap do |logger|
        logger.level = Logger::Severity::INFO
      end
    end

    def start
      # stub
    end

    def publish
      # stub
    end
  end
end
