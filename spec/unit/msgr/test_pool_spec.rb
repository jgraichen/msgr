# frozen_string_literal: true

require 'spec_helper'

describe Msgr::TestPool do
  let(:pool) { described_class.new }

  describe '.run' do
    it 'passes through to #run' do
      expect(pool).to receive(:run).with(count: 5) # rubocop:disable RSpec/MessageSpies
      described_class.run(count: 5)
    end
  end
end
