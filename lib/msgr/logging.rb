# frozen_string_literal: true

module Msgr
  module Logging
    def log(level)
      Msgr.logger.send(level) { "#{log_name} #{yield}" } if Msgr.logger
    end

    def log_name
      "[#{Thread.current.object_id.to_s(16)}]"
    end
  end
end
