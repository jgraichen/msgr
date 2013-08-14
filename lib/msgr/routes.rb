module Msgr

  class Routes
    delegate :each, to: :@routes

    def routes
      @routes ||= []
    end

    def configure(&block)
      instance_eval &block
    end

    def route(key, opts = {})
      routes << Msgr::Route.new(key, opts)
    end
  end
end
