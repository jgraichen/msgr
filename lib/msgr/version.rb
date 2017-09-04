# frozen_string_literal: true

module Msgr
  module VERSION
    MAJOR = 0
    MINOR = 15
    PATCH = 2
    STAGE = nil
    STRING = [MAJOR, MINOR, PATCH, STAGE].reject(&:nil?).join('.')

    def self.to_s
      STRING
    end
  end
end
