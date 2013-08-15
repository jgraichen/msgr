module Msgr

  module Logging
    def log(level)
      Msgr.logger.send(level, self.log_name) { yield }
    end

    def log_name
      "[#{Thread.current.object_id}] #{self.to_s}"
    end
  end
end
