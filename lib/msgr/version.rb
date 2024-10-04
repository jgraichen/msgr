# frozen_string_literal: true

module Msgr
  module VERSION
    MAJOR = 1
    MINOR = 6
    PATCH = 1
    STAGE = nil
    STRING = [MAJOR, MINOR, PATCH, STAGE].compact.join('.')

    def self.to_s
      STRING
    end
  end
end
