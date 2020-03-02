# frozen_string_literal: true

module Msgr
  class Railtie < ::Rails::Railtie
    config.msgr = ActiveSupport::OrderedOptions.new

    config.autoload_paths << File.expand_path("#{Rails.root}/app/consumers") if File.exist?("#{Rails.root}/app/consumers")

    initializer 'msgr.logger' do |app|
      app.config.msgr.logger ||= Rails.logger
    end

    # Start msgr
    initializer 'msgr.start' do
      config.after_initialize do |app|
        Msgr.logger = app.config.msgr.logger

        self.class.load app.config.msgr
      end
    end

    class << self
      def load(rails_config)
        cfg = parse_config load_config rails_config
        return unless cfg # no config given -> does not load Msgr

        Msgr.config = cfg
        Msgr.client.connect if cfg[:checkcredentials]
        Msgr.start if cfg[:autostart]
      end

      def parse_config(cfg)
        unless cfg.is_a? Hash
          Rails.logger.warn '[Msgr] Could not load rabbitmq config: Config must be a Hash'
          return nil
        end

        unless cfg[Rails.env].is_a?(Hash)
          Rails.logger.warn "Could not load rabbitmq config for environment \"#{Rails.env}\": is not a Hash"
          return nil
        end

        cfg = HashWithIndifferentAccess.new cfg[Rails.env]
        raise ArgumentError.new('Could not load rabbitmq environment config: URI missing.') unless cfg[:uri]

        case cfg[:autostart]
          when true, 'true', 'enabled'
            cfg[:autostart] = true
          when false, 'false', 'disabled', nil
            cfg[:autostart] = false
          else
            raise ArgumentError.new("Invalid value for rabbitmq config autostart: \"#{cfg[:autostart]}\"")
        end

        case cfg[:checkcredentials]
          when true, 'true', 'enabled', nil
            cfg[:checkcredentials] = true
          when false, 'false', 'disabled'
            cfg[:checkcredentials] = false
          else
            raise ArgumentError.new("Invalid value for rabbitmq config checkcredentials: \"#{cfg[:checkcredentials]}\"")
        end

        case cfg[:raise_exceptions]
          when true, 'true', 'enabled'
            cfg[:raise_exceptions] = true
          when false, 'false', 'disabled', nil
            cfg[:raise_exceptions] = false
          else
            raise ArgumentError.new("Invalid value for rabbitmq config raise_exceptions: \"#{cfg[:raise_exceptions]}\"")
        end

        cfg[:routing_file] ||= Rails.root.join('config/msgr.rb').to_s
        cfg
      end

      def load_config(options)
        if options.rabbitmq_config || !Rails.application.respond_to?(:config_for)
          load_file options.rabbitmq_config || Rails.root.join('config', 'rabbitmq.yml')
        else
          conf = Rails.application.config_for :rabbitmq

          {Rails.env.to_s => conf}
        end
      end

      def load_file(path)
        YAML.safe_load ERB.new(File.read(path)).result
      end
    end
  end
end
