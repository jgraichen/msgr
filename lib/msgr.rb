require 'msgr/version'
require 'celluloid'
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/hash/keys'
require 'json'

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
    attr_writer :client, :config
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

    def logger=(logger)
      @logger = logger
    end

    def after_load(&block)
      @after_load_callbacks ||= []
      @after_load_callbacks << block
    end

    def start
      client.start
      (@after_load_callbacks || []).each do |callback|
        callback.call client
      end
      client
    end
  end
end
