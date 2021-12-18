# frozen_string_literal: true

module Msgr
  class Railtie < ::Rails::Railtie
    config.msgr = ActiveSupport::OrderedOptions.new

    initializer 'msgr.logger' do |app|
      app.config.msgr.logger ||= Rails.logger
    end

    initializer 'msgr.start' do
      config.after_initialize do |app|
        Msgr.logger = app.config.msgr.logger
        self.class.load(app.config_for(:rabbitmq).symbolize_keys)
      end
    end

    rake_tasks do
      load File.expand_path('tasks/msgr/drain.rake', __dir__)
    end

    class << self
      def load(config)
        # Set defaults
        config.reverse_merge!(
          checkcredentials: true,
          routing_file: Rails.root.join('config/msgr.rb').to_s,
        )

        Msgr.config = config
        Msgr.client.connect if config.fetch(:checkcredentials)
      end
    end
  end
end
