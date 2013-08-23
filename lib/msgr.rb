require 'msgr/version'
require 'celluloid'
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash/reverse_merge'

require 'msgr/logging'
require 'msgr/binding'
require 'msgr/client'
require 'msgr/connection'
require 'msgr/consumer'
require 'msgr/dispatcher'
require 'msgr/errors'
require 'msgr/message'
require 'msgr/pool'
require 'msgr/route'
require 'msgr/routes'

require 'msgr/railtie' if defined? Rails

module Msgr

  class << self
    attr_accessor :client
    delegate :publish, to: :client

    def logger
      if @logger.nil?
        @logger = Logger.new $stdout
        @logger.level = Logger::Severity::INFO
      end

      @logger
    end

    def logger=(logger)
      @logger = logger
    end
  end
end
