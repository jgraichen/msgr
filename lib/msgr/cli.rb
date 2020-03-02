# frozen_string_literal: true

require 'optionparser'

module Msgr
  class CLI
    attr_reader :options

    def initialize(options)
      @options = options

      if !File.exist?(options[:require]) ||
         (File.directory?(options[:require]) && !File.exist?("#{options[:require]}/config/application.rb"))
        raise <<~ERR
          Rails application or required ruby file not found: #{options[:require]}
        ERR
      end
    end

    def run
      ENV['RACK_ENV'] = ENV['RAILS_ENV'] = options[:environment]

      if File.directory?(options[:require])
        require 'rails'
        if ::Rails::VERSION::MAJOR == 4
          require File.expand_path("#{options[:require]}/config/application.rb")
          ::Rails::Application.initializer 'msgr.eager_load' do
            ::Rails.application.config.eager_load = true
          end
          require 'msgr/railtie'
          require File.expand_path("#{options[:require]}/config/environment.rb")
        else
          require 'msgr/railtie'
          require File.expand_path("#{options[:require]}/config/environment.rb")
        end
      else
        require(options[:require])
      end

      r, w = IO.pipe

      Signal.trap('INT') { w.puts 'INT' }
      Signal.trap('TERM') { w.puts 'TERM' }

      Msgr.logger = Logger.new(STDOUT)
      Msgr.client.start

      while readable = IO.select([r])
        case readable.first[0].gets.strip
          when 'INT', 'TERM'
            Msgr.client.stop
            break
          else
            exit 1
        end
      end
    end

    class << self
      def run(argv)
        new(parse(argv)).run
      end

      private

      def parse(_argv)
        options = {
          require: Dir.pwd,
          environment: 'development'
        }

        OptionParser.new do |o|
          o.on '-r', '--require [PATH|DIR]', 'Location of Rails application (default to current directory)' do |arg|
            options[:require] = arg
          end

          o.on '-e', '--environment [env]', 'Rails environment (default to development)' do |arg|
            options[:environment] = arg
          end
        end.parse!

        options
      end
    end
  end
end
