# frozen_string_literal: true
require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.eager_load = false
    config.filter_parameters += [:password]
    config.session_store :cookie_store, key: '_dummy_session'

    config.msgr.logger = Logger.new $stdout
  end
end
