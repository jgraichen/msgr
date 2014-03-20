module Msgr

  class Routes
    include Logging
    attr_reader :routes
    delegate :each, :empty?, :size, :any?, to: :@routes

    def initialize
      @routes = []
    end

    def configure(&block)
      blocks << block
      instance_eval &block
    end

    def files
      @files ||= []
    end

    def blocks
      @blocks ||= []
    end

    def files=(files)
      @files = Array files
    end

    def <<(file)
      files << file
    end

    def reload
      routes.clear
      blocks.each { |block| instance_eval(&block) }
      files.uniq!
      files.each do |file|
        if File.exists? file
          load file
        else
          log(:warn) { "Routes file `#{file}` does not exists (anymore)." }
        end
      end
    end

    def load(file)
      raise ArgumentError.new "File `#{file}` does not exists." unless File.exists? file
      instance_eval File.read file
    end

    def route(key, opts = {})
      routes.each do |route|
        if route.accept? key, opts
          route.add key
          return
        end
      end

      routes << Msgr::Route.new(key, opts)
    end
  end
end
