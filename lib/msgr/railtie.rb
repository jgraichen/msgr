module Msgr

  class Railtie < ::Rails::Railtie
    config.msgr = ActiveSupport::OrderedOptions.new
    config.autoload_paths << File.expand_path("#{Rails.root}/app/consumers") if File.exist?("#{Rails.root}/app/consumers")

    initializer 'msgr.logger' do |app|
      app.config.msgr.logger ||= Rails.logger
    end

    initializer 'msgr.rabbitmq_config' do
      config.msgr.rabbitmq_config ||= Rails.root.join *%w(config rabbitmq.yml)
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
        cfg = parse_config load_config rails_config.rabbitmq_config.to_s
        return unless cfg # no config given -> does not load Msgr

        Msgr.config = cfg
        Msgr.client.connect
      end

      def parse_config(cfg)
        unless cfg.is_a? Hash
          Rails.logger.wanr '[Msgr] Could not load rabbitmq config: Config must be a Hash'
          return nil
        end

        unless cfg[Rails.env].is_a?(Hash)
          raise ArgumentError, "Could not load rabbitmq config for environment \"#{Rails.env}\": is not a Hash"
        end

        cfg = HashWithIndifferentAccess.new cfg[Rails.env]
        unless cfg[:uri]
          raise ArgumentError, 'Could not load rabbitmq environment config: URI missing.'
        end

        case cfg[:autostart]
          when true, 'true', 'enabled', nil
            cfg[:autostart] = true
          when false, 'false', 'disabled'
            cfg[:autostart] = false
          else
            raise ArgumentError, "Invalid value for rabbitmq config autostart: \"#{cfg[:autostart]}\""
        end

        cfg[:routing_file] ||= Rails.root.join('config/msgr.rb').to_s
        cfg
      end

      def load_config(file)
        YAML.load ERB.new(File.read(file)).result
      end
    end
  end
end
