module Msgr
  module VERSION
    MAJOR = 0
    MINOR = 11
    PATCH = 0
    STAGE = 'rc2'
    STRING = [MAJOR, MINOR, PATCH, STAGE].reject(&:nil?).join('.')

    def self.to_s; STRING end
  end
end
