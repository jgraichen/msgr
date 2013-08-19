module Msgr

  class Routes
    attr_reader :routes
    delegate :each, to: :@routes

    def initialize
      @routes = []
    end

    def configure(&block)
      instance_eval &block
    end

    def files
      @files ||= []
    end

    def files=(files)
      @files = Array files
    end

    def reload
      files.each do |file|
        if File.exists? file
          load file
        else
          Msgr.logger.warn "Routes file `#{file}` does not exists (anymore)."
        end
      end
    end

    def load(file)
      raise ArgumentError.new "File `#{file}` does not exists." unless File.exists? file
      instance_eval File.read file
    end

    def route(key, opts = {})
      routes << Msgr::Route.new(key, opts)
    end
  end
end
