# frozen_string_literal: true
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
      instance_eval(&block)
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
      blocks.each {|block| instance_eval(&block) }
      files.uniq!
      files.each do |file|
        if File.exist? file
          load file
        else
          log(:warn) { "Routes file `#{file}` does not exists (anymore)." }
        end
      end
    end

    def load(file)
      unless File.exist?(file)
        raise ArgumentError.new "File `#{file}` does not exists."
      end

      instance_eval File.read file
    end

    def route(key, opts = {})
      if (route = routes.find {|r| r.accept?(key, opts) })
        route.add key
      else
        routes << Msgr::Route.new(key, opts)
      end
    end
  end
end
