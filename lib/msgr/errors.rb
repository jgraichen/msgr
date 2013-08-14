module Msgr

  # Abstract error base class
  class CausedByError < StandardError
    attr_accessor :cause

    def initialize(*args)
      opts = args.extract_options!
      @cause = opts.delete(:cause)
      super
    end

    def message
      cause ? "#{super}\n  caused by:\n#{cause.to_s}" : super
    end
  end

  class ConnectionError < CausedByError

  end
end
