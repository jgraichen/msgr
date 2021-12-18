# frozen_string_literal: true

require 'msgr/version'
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/hash/keys'

require 'msgr/logging'
require 'msgr/client'
require 'msgr/binding'
require 'msgr/channel'
require 'msgr/connection'
require 'msgr/consumer'
require 'msgr/dispatcher'
require 'msgr/errors'
require 'msgr/message'
require 'msgr/route'
require 'msgr/routes'
require 'msgr/test_pool'

require 'msgr/railtie' if defined? Rails

module Msgr
  class << self
    attr_writer :client, :config, :logger

    delegate :publish, to: :client

    def config
      @config ||= {}
    end

    def client
      @client ||= Msgr::Client.new config
    end

    def logger
      if @logger.nil?
        @logger = Logger.new $stdout
        @logger.level = Logger::Severity::INFO
      end

      @logger
    end

    def start
      client.start
      client
    end
  end
end
