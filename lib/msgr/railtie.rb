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

    initializer 'msgr.routes_file' do
      config.msgr.routes_file ||= Rails.root.join *%w(config msgr.rb)
    end

    # Start msgr
    initializer 'msgr.start' do
      config.after_initialize do |app|
        Msgr.logger = app.config.msgr.logger
        Celluloid.logger = app.config.msgr.logger

        cfile  = app.config.msgr.rabbitmq_config.to_s
        config = YAML.load ERB.new(File.read(cfile)).result

        raise ArgumentError, 'Could not load rabbitmq config: Config must be a Hash' unless config.is_a? Hash

        if config[Rails.env].is_a?(Hash)
          cfg = HashWithIndifferentAccess.new config[Rails.env]

          if cfg[:enabled].nil? || cfg[:enabled] == 'true'
            if cfg[:uri]
              client = Msgr::Client.new
              client.routes.files << app.config.msgr.routes_file
              client.routes.reload

              if Rails.env.development? || config
                reloader = ActiveSupport::FileUpdateChecker.new client.routes.files do
                  client.routes.reload
                  client.reload
                end

                ActionDispatch::Reloader.to_prepare do
                  reloader.execute_if_updated
                end
              end

              Msgr.client = client
              client.start
            else
              raise ArgumentError, 'Could not load rabbitmq environment config: URI missing.'
            end
          end
        else
          if Rails.env.production?
            raise ArgumentError, 'Could not load rabbitmq environment config: Not a hash.'
          else
            Rails.logger.warn 'Could not load rabbitmq environment config: Not a hash.'
          end
        end
      end
    end
  end
end
