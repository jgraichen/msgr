# frozen_string_literal: true

module Msgr
  class Railtie < ::Rails::Railtie
    config.msgr = ActiveSupport::OrderedOptions.new

    DEFAULT_OPTIONS = {
      checkcredentials: true,
      routing_file: "#{Rails.root}/config/msgr.rb"
    }.freeze

    if File.exist?("#{Rails.root}/app/consumers")
      config.autoload_paths << File.expand_path("#{Rails.root}/app/consumers")
    end

    initializer 'msgr.logger' do |app|
      app.config.msgr.logger ||= Rails.logger
    end

    initializer 'msgr.start' do
      config.after_initialize do |app|
        Msgr.logger = app.config.msgr.logger

        self.class.load(app.config_for(:rabbitmq))
      end
    end

    rake_tasks do
      load File.expand_path('tasks/msgr/drain.rake', __dir__)
    end

    class << self
      def load(config)
        config = DEFAULT_OPTIONS.merge(config)

        Msgr.config = config
        Msgr.client.connect if config.fetch(:checkcredentials)
      end
    end
  end
end
