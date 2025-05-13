# frozen_string_literal: true

module Msgr
  module Logging
    def log(level)
      # rubocop:disable Style/SafeNavigation -- Msgr.logger can be false
      Msgr.logger.send(level) { "#{log_name} #{yield}" } if Msgr.logger
      # rubocop:enable all
    end

    def log_name
      "[#{Thread.current.object_id.to_s(16)}]"
    end
  end
end
