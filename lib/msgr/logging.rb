module Msgr

  module Logging
    def log(level)
      Msgr.logger.send(level) { "#{self.log_name} #{yield}" } if Msgr.logger
    end

    def log_name
      "[#{Thread.current.object_id.to_s(16)}] <#{self.class.name}[#{object_id.to_s(16)}]>"
    end
  end
end
